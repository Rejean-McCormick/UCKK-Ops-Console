# -*- coding: utf-8 -*-
"""
UCKK - Installation neuve / reprise Moodle 5.2 stable
Windows + Python 3 + Tkinter

But:
- un seul workflow principal, relançable;
- vérifie ce qui est déjà OK et le saute;
- crée automatiquement la DB MariaDB et l'utilisateur Moodle;
- secrets persistés dans les variables d'environnement utilisateur Windows;
- log verbeux, persistant et copiable;
- aucune suppression automatique d'une DB, d'un core ou d'un moodledata existant.
"""

from __future__ import annotations

import datetime as dt
import json
import os
import queue
import re
import secrets
import shutil
import string
import subprocess
import threading
import time
import traceback
import tkinter as tk
from pathlib import Path
from tkinter import messagebox, ttk


APP_TITLE = "UCKK - Installer Moodle 5.2 stable"
MOODLE_REPO = "https://github.com/moodle/moodle.git"
MOODLE_BRANCH = "MOODLE_502_STABLE"

DEFAULT_MOODLE_ROOT = r"C:\mycode\UCKK\moodle\moodle"
DEFAULT_STAGING = r"C:\mycode\UCKK\moodle\moodle_52_staging"
DEFAULT_MOODLEDATA = r"C:\mycode\UCKK\moodledata"
DEFAULT_OPS = r"C:\mycode\UCKK\UCKK_ops_console"
DEFAULT_WWWROOT = "http://127.0.0.1:8000"

ENV_DB_ADMIN_USER = "UCKK_DB_ADMIN_USER"
ENV_DB_ADMIN_PASSWORD = "UCKK_DB_ADMIN_PASSWORD"
ENV_MOODLE_DB_PASSWORD = "UCKK_MOODLE_DB_PASSWORD"
ENV_MOODLE_ADMIN_PASSWORD = "UCKK_MOODLE_ADMIN_PASSWORD"

VALID_DBTYPE = "mariadb"


class InstallError(RuntimeError):
    pass


def now_stamp() -> str:
    return dt.datetime.now().strftime("%Y%m%d_%H%M%S")


def sql_literal(value: str) -> str:
    return "'" + value.replace("\\", "\\\\").replace("'", "''") + "'"


class App(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title(APP_TITLE)
        self.geometry("1120x790")
        self.minsize(950, 680)

        self.busy = False
        self.q: queue.Queue[tuple[str, str]] = queue.Queue()
        self.log_lock = threading.Lock()

        self.var_root = tk.StringVar(value=DEFAULT_MOODLE_ROOT)
        self.var_staging = tk.StringVar(value=DEFAULT_STAGING)
        self.var_dataroot = tk.StringVar(value=DEFAULT_MOODLEDATA)
        self.var_ops = tk.StringVar(value=DEFAULT_OPS)
        self.var_wwwroot = tk.StringVar(value=DEFAULT_WWWROOT)

        self.var_dbhost = tk.StringVar(value="127.0.0.1")
        self.var_dbname = tk.StringVar(value="uckk_moodle_52")
        self.var_dbuser = tk.StringVar(value="uckk_moodle")
        self.var_db_admin_user = tk.StringVar(
            value=os.environ.get(ENV_DB_ADMIN_USER, "root")
        )
        self.var_db_admin_pass = tk.StringVar(
            value=os.environ.get(ENV_DB_ADMIN_PASSWORD, "")
        )
        self.var_dbpass = tk.StringVar(
            value=os.environ.get(ENV_MOODLE_DB_PASSWORD, "")
        )

        self.var_adminuser = tk.StringVar(value="admin")
        self.var_adminpass = tk.StringVar(
            value=os.environ.get(ENV_MOODLE_ADMIN_PASSWORD, "")
        )
        self.var_fullname = tk.StringVar(value="UCKK Local")
        self.var_shortname = tk.StringVar(value="UCKK")

        self.var_launch_ops = tk.BooleanVar(value=True)

        self.state_file = Path(__file__).with_suffix(".state.json")
        self.session_log = Path(__file__).with_name(
            f"UCKK_Moodle52_install_{now_stamp()}.log"
        )

        self._load_state()
        self._build_ui()
        self.after(100, self._drain)
        self._log("SESSION", f"Journal: {self.session_log}")
        self._log("INFO", "Prêt. Renseigne seulement le mot de passe MariaDB root si nécessaire, puis clique « Installer / reprendre Moodle 5.2 ».")

    # ------------------------------------------------------------------ UI

    def _build_ui(self):
        outer = ttk.Frame(self, padding=10)
        outer.pack(fill="both", expand=True)

        ttk.Label(
            outer,
            text="UCKK - installation neuve Moodle 5.2 stable",
            font=("Segoe UI", 16, "bold"),
        ).pack(anchor="w")

        ttk.Label(
            outer,
            text=(
                "Un seul workflow relançable : ce qui est déjà correct est détecté et sauté. "
                "Aucune ancienne DB n'est downgradée."
            ),
        ).pack(anchor="w", pady=(2, 10))

        paned = ttk.Panedwindow(outer, orient="vertical")
        paned.pack(fill="both", expand=True)

        top = ttk.Frame(paned, padding=8)
        bottom = ttk.Frame(paned, padding=8)
        paned.add(top, weight=1)
        paned.add(bottom, weight=2)

        self._build_config(top)
        self._build_log(bottom)

        self.status = ttk.Label(outer, text="Prêt", anchor="w")
        self.status.pack(fill="x", pady=(8, 0))

    def _row(self, parent, row, label, var, show=None):
        ttk.Label(parent, text=label).grid(row=row, column=0, sticky="w", padx=(0, 8), pady=3)
        e = ttk.Entry(parent, textvariable=var, show=show)
        e.grid(row=row, column=1, sticky="ew", pady=3)
        parent.columnconfigure(1, weight=1)
        return e

    def _build_config(self, f):
        left = ttk.LabelFrame(f, text="Installation locale", padding=8)
        right = ttk.LabelFrame(f, text="MariaDB / Moodle", padding=8)
        left.grid(row=0, column=0, sticky="nsew", padx=(0, 6))
        right.grid(row=0, column=1, sticky="nsew", padx=(6, 0))
        f.columnconfigure(0, weight=1)
        f.columnconfigure(1, weight=1)

        self._row(left, 0, "Moodle root", self.var_root)
        self._row(left, 1, "Staging 5.2", self.var_staging)
        self._row(left, 2, "moodledata", self.var_dataroot)
        self._row(left, 3, "URL locale", self.var_wwwroot)
        self._row(left, 4, "Ops Console", self.var_ops)

        self._row(right, 0, "MariaDB host", self.var_dbhost)
        self._row(right, 1, "DB Moodle", self.var_dbname)
        self._row(right, 2, "Utilisateur DB Moodle", self.var_dbuser)
        self._row(right, 3, "Utilisateur MariaDB admin", self.var_db_admin_user)
        self._row(right, 4, "Mot de passe MariaDB admin", self.var_db_admin_pass, show="•")
        self._row(right, 5, "Mot de passe DB Moodle", self.var_dbpass, show="•")
        self._row(right, 6, "Admin Moodle", self.var_adminuser)
        self._row(right, 7, "Mot de passe admin Moodle", self.var_adminpass, show="•")

        buttons = ttk.Frame(f)
        buttons.grid(row=1, column=0, columnspan=2, sticky="ew", pady=(10, 0))

        self.btn_install = ttk.Button(
            buttons,
            text="Installer / reprendre Moodle 5.2",
            command=lambda: self._start(self.action_install_or_resume),
        )
        self.btn_install.pack(side="left")

        ttk.Button(
            buttons,
            text="Enregistrer secrets dans ENV",
            command=self.save_secrets_to_env,
        ).pack(side="left", padx=(8, 0))

        ttk.Button(
            buttons,
            text="Lancer Ops Console",
            command=lambda: self._start(self.action_launch_ops),
        ).pack(side="left", padx=(8, 0))

        ttk.Checkbutton(
            buttons,
            text="Lancer Ops Console automatiquement à la fin",
            variable=self.var_launch_ops,
        ).pack(side="left", padx=(14, 0))

        ttk.Label(
            f,
            text=(
                "Secrets ENV : UCKK_DB_ADMIN_PASSWORD, UCKK_MOODLE_DB_PASSWORD, "
                "UCKK_MOODLE_ADMIN_PASSWORD. Si les deux derniers sont vides, ils sont générés automatiquement."
            ),
        ).grid(row=2, column=0, columnspan=2, sticky="w", pady=(8, 0))

    def _build_log(self, f):
        toolbar = ttk.Frame(f)
        toolbar.pack(fill="x", pady=(0, 6))

        ttk.Label(toolbar, text="Journal détaillé", font=("Segoe UI", 10, "bold")).pack(side="left")
        ttk.Button(toolbar, text="Copier tout", command=self.copy_log).pack(side="right")
        ttk.Button(toolbar, text="Ouvrir le fichier log", command=self.open_log).pack(side="right", padx=(0, 6))
        ttk.Button(toolbar, text="Effacer l'affichage", command=self.clear_log).pack(side="right", padx=(0, 6))

        body = ttk.Frame(f)
        body.pack(fill="both", expand=True)

        self.txt = tk.Text(body, wrap="none", font=("Consolas", 10))
        self.txt.pack(side="left", fill="both", expand=True)

        sy = ttk.Scrollbar(body, orient="vertical", command=self.txt.yview)
        sy.pack(side="right", fill="y")
        sx = ttk.Scrollbar(f, orient="horizontal", command=self.txt.xview)
        sx.pack(fill="x")

        self.txt.configure(yscrollcommand=sy.set, xscrollcommand=sx.set)
        self.txt.tag_configure("ERROR", foreground="#b00020")
        self.txt.tag_configure("WARN", foreground="#996000")
        self.txt.tag_configure("OK", foreground="#08752a")
        self.txt.tag_configure("PHASE", foreground="#5a2ca0")
        self.txt.tag_configure("SKIP", foreground="#555555")
        self.txt.tag_configure("INFO", foreground="#174f91")
        self.txt.tag_configure("CMD", foreground="#333333")

    # ---------------------------------------------------------------- log

    def _log(self, level: str, message: str):
        ts = dt.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        line = f"[{ts}] [{level}] {message}"
        self.q.put((level, line + "\n"))

        try:
            with self.log_lock:
                self.session_log.parent.mkdir(parents=True, exist_ok=True)
                with self.session_log.open("a", encoding="utf-8", newline="\n") as fh:
                    fh.write(line + "\n")
        except Exception:
            pass

    def _phase(self, name: str):
        self._log("PHASE", "=" * 72)
        self._log("PHASE", name)
        self._log("PHASE", "=" * 72)

    def _drain(self):
        try:
            while True:
                level, line = self.q.get_nowait()
                tag = level if level in {"ERROR", "WARN", "OK", "PHASE", "SKIP", "INFO", "CMD"} else "INFO"
                self.txt.insert("end", line, tag)
                self.txt.see("end")
                self.status.configure(text=line.strip())
        except queue.Empty:
            pass
        self.after(100, self._drain)

    def copy_log(self):
        text = self.txt.get("1.0", "end-1c")
        self.clipboard_clear()
        self.clipboard_append(text)
        self.update()
        self.status.configure(text="Journal copié dans le presse-papiers.")

    def open_log(self):
        try:
            if not self.session_log.exists():
                self.session_log.touch()
            os.startfile(str(self.session_log))
        except Exception as exc:
            messagebox.showerror(APP_TITLE, str(exc))

    def clear_log(self):
        self.txt.delete("1.0", "end")

    # -------------------------------------------------------------- threading

    def _start(self, fn):
        if self.busy:
            messagebox.showwarning(APP_TITLE, "Une opération est déjà en cours.")
            return
        self.busy = True
        self.btn_install.configure(state="disabled")

        def worker():
            try:
                fn()
            except Exception as exc:
                self._log("ERROR", f"{type(exc).__name__}: {exc}")
                self._log("ERROR", "DÉTAIL TECHNIQUE:")
                for line in traceback.format_exc().rstrip().splitlines():
                    self._log("ERROR", line)
                self.after(0, lambda e=str(exc): messagebox.showerror(
                    APP_TITLE,
                    f"{e}\n\nLe détail complet est dans le journal.\n{self.session_log}"
                ))
            finally:
                self.busy = False
                self.after(0, lambda: self.btn_install.configure(state="normal"))

        threading.Thread(target=worker, daemon=True).start()

    def _ask_yesno(self, message: str) -> bool:
        done = threading.Event()
        result = {"v": False}

        def ask():
            try:
                result["v"] = messagebox.askyesno(APP_TITLE, message)
            finally:
                done.set()

        self.after(0, ask)
        done.wait()
        return bool(result["v"])

    # ------------------------------------------------------------- persistence

    def _set_user_env(self, name: str, value: str):
        if os.name != "nt":
            raise InstallError("Ce programme est prévu pour Windows.")
        proc = subprocess.run(
            ["setx", name, value],
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            encoding="utf-8",
            errors="replace",
            creationflags=subprocess.CREATE_NO_WINDOW,
        )
        if proc.returncode != 0:
            raise InstallError(f"Impossible d'enregistrer {name} dans l'environnement utilisateur.")
        os.environ[name] = value

    def _save_state(self):
        data = {
            "root": self.var_root.get(),
            "staging": self.var_staging.get(),
            "dataroot": self.var_dataroot.get(),
            "ops": self.var_ops.get(),
            "wwwroot": self.var_wwwroot.get(),
            "dbhost": self.var_dbhost.get(),
            "dbname": self.var_dbname.get(),
            "dbuser": self.var_dbuser.get(),
            "db_admin_user": self.var_db_admin_user.get(),
            "adminuser": self.var_adminuser.get(),
            "fullname": self.var_fullname.get(),
            "shortname": self.var_shortname.get(),
            "launch_ops": self.var_launch_ops.get(),
        }
        self.state_file.write_text(
            json.dumps(data, ensure_ascii=False, indent=2),
            encoding="utf-8",
        )

    def _load_state(self):
        if not self.state_file.exists():
            return
        try:
            data = json.loads(self.state_file.read_text(encoding="utf-8"))
            mapping = {
                "root": self.var_root,
                "staging": self.var_staging,
                "dataroot": self.var_dataroot,
                "ops": self.var_ops,
                "wwwroot": self.var_wwwroot,
                "dbhost": self.var_dbhost,
                "dbname": self.var_dbname,
                "dbuser": self.var_dbuser,
                "db_admin_user": self.var_db_admin_user,
                "adminuser": self.var_adminuser,
                "fullname": self.var_fullname,
                "shortname": self.var_shortname,
            }
            for key, var in mapping.items():
                if key in data and data[key] not in (None, ""):
                    var.set(data[key])
            if "launch_ops" in data:
                self.var_launch_ops.set(bool(data["launch_ops"]))
        except Exception:
            pass

    def _ensure_secrets(self):
        admin_pass = self.var_db_admin_pass.get() or os.environ.get(ENV_DB_ADMIN_PASSWORD, "")
        if not admin_pass:
            raise InstallError(
                "Mot de passe MariaDB admin manquant.\n"
                "Entre ton mot de passe MariaDB root/admin dans l'interface puis relance."
            )

        db_pass = self.var_dbpass.get() or os.environ.get(ENV_MOODLE_DB_PASSWORD, "")
        if not db_pass:
            db_pass = secrets.token_urlsafe(28)
            self.var_dbpass.set(db_pass)
            self._log("INFO", f"{ENV_MOODLE_DB_PASSWORD} absent: génération automatique d'un mot de passe fort.")

        moodle_admin_pass = self.var_adminpass.get() or os.environ.get(ENV_MOODLE_ADMIN_PASSWORD, "")
        if not moodle_admin_pass:
            moodle_admin_pass = secrets.token_urlsafe(28)
            self.var_adminpass.set(moodle_admin_pass)
            self._log("INFO", f"{ENV_MOODLE_ADMIN_PASSWORD} absent: génération automatique d'un mot de passe fort.")

        admin_user = self.var_db_admin_user.get().strip() or "root"

        self._set_user_env(ENV_DB_ADMIN_USER, admin_user)
        self._set_user_env(ENV_DB_ADMIN_PASSWORD, admin_pass)
        self._set_user_env(ENV_MOODLE_DB_PASSWORD, db_pass)
        self._set_user_env(ENV_MOODLE_ADMIN_PASSWORD, moodle_admin_pass)

        self._log("OK", "Secrets disponibles et enregistrés dans l'environnement utilisateur Windows.")
        return admin_pass, db_pass, moodle_admin_pass

    def save_secrets_to_env(self):
        try:
            self._ensure_secrets()
            self._save_state()
            messagebox.showinfo(
                APP_TITLE,
                "Secrets enregistrés dans les variables d'environnement utilisateur Windows."
            )
        except Exception as exc:
            messagebox.showerror(APP_TITLE, str(exc))

    # --------------------------------------------------------------- helpers

    def _which(self, *names: str) -> str | None:
        for name in names:
            p = shutil.which(name)
            if p:
                return p
        return None

    def _find_mysql_client(self) -> str | None:
        """Trouve automatiquement mariadb.exe/mysql.exe même s'il n'est pas dans PATH."""
        direct = self._which("mariadb.exe", "mariadb", "mysql.exe", "mysql")
        if direct:
            return direct

        candidates = []
        env_roots = [
            os.environ.get("ProgramFiles"),
            os.environ.get("ProgramFiles(x86)"),
            os.environ.get("LOCALAPPDATA"),
            os.environ.get("USERPROFILE"),
            os.environ.get("ChocolateyInstall"),
        ]

        # Installations MariaDB/MySQL classiques.
        for root_text in env_roots:
            if not root_text:
                continue
            root = Path(root_text)
            patterns = [
                "MariaDB */bin/mariadb.exe",
                "MariaDB */bin/mysql.exe",
                "MySQL/MySQL Server */bin/mysql.exe",
                "Programs/MariaDB */bin/mariadb.exe",
                "Programs/MariaDB */bin/mysql.exe",
            ]
            for pattern in patterns:
                try:
                    candidates.extend(root.glob(pattern))
                except Exception:
                    pass

        # Stacks de dev courantes.
        fixed = [
            Path(r"C:\xampp\mysql\bin\mysql.exe"),
            Path(r"C:\xampp\mysql\bin\mariadb.exe"),
            Path(r"C:\wamp64\bin\mariadb"),
            Path(r"C:\wamp64\bin\mysql"),
            Path(r"C:\laragon\bin\mysql"),
            Path(r"C:\laragon\bin\mariadb"),
            Path(r"C:\tools"),
        ]

        for p in fixed:
            if p.is_file():
                candidates.append(p)
            elif p.is_dir():
                try:
                    candidates.extend(p.glob("**/bin/mariadb.exe"))
                    candidates.extend(p.glob("**/bin/mysql.exe"))
                except Exception:
                    pass

        # Chocolatey / Scoop.
        choco = os.environ.get("ChocolateyInstall")
        if choco:
            croot = Path(choco) / "bin"
            for name in ("mariadb.exe", "mysql.exe"):
                p = croot / name
                if p.is_file():
                    candidates.append(p)

        user = Path(os.environ.get("USERPROFILE", r"C:\Users\Default"))
        scoop = user / "scoop" / "apps"
        if scoop.is_dir():
            try:
                candidates.extend(scoop.glob("mariadb/*/bin/mariadb.exe"))
                candidates.extend(scoop.glob("mysql/*/bin/mysql.exe"))
            except Exception:
                pass

        # Dédupliquer et privilégier mariadb.exe.
        existing = []
        seen = set()
        for p in candidates:
            try:
                rp = str(p.resolve())
            except Exception:
                rp = str(p)
            key = rp.lower()
            if key in seen or not Path(rp).is_file():
                continue
            seen.add(key)
            existing.append(Path(rp))

        existing.sort(key=lambda p: (0 if p.name.lower() == "mariadb.exe" else 1, str(p).lower()))
        return str(existing[0]) if existing else None

    def _run(self, args, cwd=None, env=None, input_text=None, redact=(), check=True):
        shown = " ".join(str(x) for x in args)
        for secret in redact:
            if secret:
                shown = shown.replace(secret, "********")

        self._log("CMD", f"$ {shown}")
        if cwd:
            self._log("CMD", f"CWD: {cwd}")

        start = time.monotonic()
        proc = subprocess.run(
            [str(x) for x in args],
            cwd=str(cwd) if cwd else None,
            env=env,
            input=input_text,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            encoding="utf-8",
            errors="replace",
            creationflags=subprocess.CREATE_NO_WINDOW if os.name == "nt" else 0,
        )
        elapsed = time.monotonic() - start

        output = proc.stdout or ""
        for line in output.rstrip().splitlines():
            self._log("CMD", f"| {line}")

        self._log(
            "CMD",
            f"EXIT={proc.returncode}  DURÉE={elapsed:.2f}s"
        )

        if check and proc.returncode != 0:
            raise InstallError(
                f"Commande échouée (exit={proc.returncode}). "
                "Voir le journal pour stdout/stderr complet."
            )
        return proc.returncode, output

    def _read_version(self, root: Path) -> dict:
        for p in (root / "public" / "version.php", root / "version.php"):
            if not p.is_file():
                continue
            raw = p.read_text(encoding="utf-8", errors="replace")
            out = {"path": str(p), "version": "", "release": "", "branch": "", "maturity": ""}
            patterns = {
                "version": r"(?m)^\s*\$version\s*=\s*([0-9]+(?:\.[0-9]+)?)\s*;",
                "release": r"""(?m)^\s*\$release\s*=\s*['"]([^'"]+)['"]\s*;""",
                "branch": r"""(?m)^\s*\$branch\s*=\s*['"]([^'"]+)['"]\s*;""",
                "maturity": r"(?m)^\s*\$maturity\s*=\s*([A-Z0-9_]+)\s*;",
            }
            for key, pattern in patterns.items():
                m = re.search(pattern, raw)
                if m:
                    out[key] = m.group(1)
            return out
        return {}

    def _is_stable_52(self, root: Path) -> bool:
        info = self._read_version(root)
        return info.get("branch") == "502" and info.get("maturity") == "MATURITY_STABLE"

    def _validate_identifier(self, value: str, label: str):
        if not re.fullmatch(r"[A-Za-z0-9_]+", value or ""):
            raise InstallError(f"{label} invalide: {value!r}. Utilise lettres, chiffres et underscore.")

    def _mysql(self, sql: str, user: str, password: str, database: str | None = None, check=True):
        exe = self._find_mysql_client()
        if not exe:
            raise InstallError("Client MariaDB/MySQL introuvable dans PATH.")

        args = [exe, "-h", self.var_dbhost.get().strip() or "127.0.0.1", "-u", user, "--batch", "--skip-column-names"]
        if database:
            args += [database]

        env = os.environ.copy()
        env["MYSQL_PWD"] = password
        return self._run(
            args,
            env=env,
            input_text=sql + "\n",
            redact=(password,),
            check=check,
        )

    # ---------------------------------------------------------- composite flow

    def action_install_or_resume(self):
        self._save_state()
        self._phase("INSTALLATION / REPRISE MOODLE 5.2")

        root = Path(self.var_root.get().strip())
        staging = Path(self.var_staging.get().strip())
        dataroot = Path(self.var_dataroot.get().strip())

        dbhost = self.var_dbhost.get().strip() or "127.0.0.1"
        dbname = self.var_dbname.get().strip()
        dbuser = self.var_dbuser.get().strip()
        dbadmin = self.var_db_admin_user.get().strip() or "root"
        wwwroot = self.var_wwwroot.get().strip()
        adminuser = self.var_adminuser.get().strip() or "admin"

        self._validate_identifier(dbname, "Nom de DB")
        self._validate_identifier(dbuser, "Utilisateur DB Moodle")
        self._validate_identifier(dbadmin, "Utilisateur DB admin")

        # 1. Prérequis strictement nécessaires.
        self._phase("1/5 - PRÉREQUIS")
        php = self._which("php.exe", "php")
        git = self._which("git.exe", "git")
        mysql = self._find_mysql_client()

        missing = []
        if not php:
            missing.append("PHP CLI")
        if not git:
            missing.append("Git")
        if not mysql:
            missing.append("client MariaDB/MySQL (mariadb.exe/mysql.exe)")
        if missing:
            raise InstallError("Prérequis manquants: " + ", ".join(missing))

        self._log("OK", f"PHP: {php}")
        self._log("OK", f"Git: {git}")
        self._log("OK", f"MariaDB/MySQL client détecté: {mysql}")
        self._run([php, "-v"], check=True)

        db_admin_pass, db_pass, moodle_admin_pass = self._ensure_secrets()

        # 2. Core Moodle 5.2: réutiliser ce qui existe, sinon staging, sinon clone.
        self._phase("2/5 - CORE MOODLE 5.2")

        if root.exists():
            if self._is_stable_52(root):
                info = self._read_version(root)
                self._log("SKIP", f"Core déjà prêt: {root}")
                self._log("OK", f"{info.get('release')} / {info.get('maturity')}")
            else:
                info = self._read_version(root)
                raise InstallError(
                    f"Le dossier Moodle existe mais n'est pas un core 5.2 stable: {root}\n"
                    f"Release={info.get('release') or 'inconnue'}, "
                    f"branch={info.get('branch') or 'inconnue'}, "
                    f"maturity={info.get('maturity') or 'inconnue'}.\n"
                    "Aucune suppression automatique n'est effectuée."
                )
        else:
            if staging.exists():
                if self._is_stable_52(staging):
                    self._log("SKIP", f"Staging 5.2 déjà valide: {staging}")
                else:
                    invalid = staging.with_name(staging.name + "_invalid_" + now_stamp())
                    self._log("WARN", f"Staging existant invalide; conservation sous: {invalid}")
                    staging.rename(invalid)

            if not staging.exists():
                staging.parent.mkdir(parents=True, exist_ok=True)
                self._log("INFO", f"Téléchargement de {MOODLE_BRANCH}...")
                self._run([
                    git, "clone",
                    "--branch", MOODLE_BRANCH,
                    "--single-branch",
                    "--depth", "1",
                    MOODLE_REPO,
                    str(staging),
                ])

            if not self._is_stable_52(staging):
                info = self._read_version(staging)
                raise InstallError(
                    f"Le staging téléchargé n'est pas Moodle 5.2 stable: {info}"
                )

            root.parent.mkdir(parents=True, exist_ok=True)
            self._log("INFO", f"Activation du core: {staging} -> {root}")
            staging.rename(root)
            self._log("OK", f"Core Moodle 5.2 activé: {root}")

        install_php = root / "admin" / "cli" / "install.php"
        cfg_php = root / "admin" / "cli" / "cfg.php"
        if not install_php.is_file():
            raise InstallError(f"Script Moodle absent: {install_php}")

        # 3. moodledata: créer ou réutiliser.
        self._phase("3/5 - MOODLEDATA")
        if dataroot.exists():
            if not dataroot.is_dir():
                raise InstallError(f"moodledata existe mais n'est pas un dossier: {dataroot}")
            self._log("SKIP", f"moodledata existe déjà: {dataroot}")
        else:
            dataroot.mkdir(parents=True, exist_ok=True)
            self._log("OK", f"moodledata créé: {dataroot}")

        # 4. DB et utilisateur MariaDB: idempotent.
        self._phase("4/5 - MARIADB")

        # Vérifie admin DB avant d'aller plus loin.
        self._mysql("SELECT VERSION();", dbadmin, db_admin_pass, check=True)
        self._log("OK", f"Connexion MariaDB admin réussie: {dbadmin}@{dbhost}")
        self._log("OK", "Driver Moodle sélectionné: mariadb")

        dbpass_sql = sql_literal(db_pass)
        user_sql = sql_literal(dbuser)

        setup_sql = f"""
CREATE DATABASE IF NOT EXISTS `{dbname}` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS {user_sql}@'localhost' IDENTIFIED BY {dbpass_sql};
ALTER USER {user_sql}@'localhost' IDENTIFIED BY {dbpass_sql};
CREATE USER IF NOT EXISTS {user_sql}@'127.0.0.1' IDENTIFIED BY {dbpass_sql};
ALTER USER {user_sql}@'127.0.0.1' IDENTIFIED BY {dbpass_sql};
GRANT ALL PRIVILEGES ON `{dbname}`.* TO {user_sql}@'localhost';
GRANT ALL PRIVILEGES ON `{dbname}`.* TO {user_sql}@'127.0.0.1';
FLUSH PRIVILEGES;
"""
        self._mysql(setup_sql, dbadmin, db_admin_pass, check=True)
        self._log("OK", f"DB et droits prêts: {dbname} / utilisateur {dbuser}")

        rc, table_out = self._mysql(
            "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = DATABASE();",
            dbuser,
            db_pass,
            database=dbname,
            check=True,
        )
        try:
            table_count = int((table_out or "0").strip().splitlines()[-1])
        except Exception:
            table_count = -1

        self._log("INFO", f"Tables actuellement présentes dans {dbname}: {table_count}")

        # 5. Installation: sauter si déjà installée; continuer si DB vide.
        self._phase("5/5 - INSTALLATION MOODLE")

        # Moodle 5.2 contient un public/config.php dans le code distribué.
        # Ce fichier ne signifie PAS que le site est déjà installé.
        # Les scripts CLI chargent le vrai config.php à la racine Moodle.
        root_config = root / "config.php"
        config_exists = root_config.is_file()

        if config_exists and table_count == 0:
            # Cas typique d'une installation interrompue très tôt :
            # install.php a déjà écrit config.php, mais aucune table Moodle
            # n'a été créée. On conserve le fichier pour diagnostic, puis on
            # repart proprement avec la DB vide.
            partial_backup = root_config.with_name(
                f"config.php.partial_{now_stamp()}.bak"
            )
            self._log(
                "WARN",
                "État partiel détecté: config.php existe mais la DB Moodle est vide."
            )
            self._log(
                "INFO",
                f"Sauvegarde du config.php partiel: {root_config} -> {partial_backup}"
            )
            root_config.rename(partial_backup)
            config_exists = False
            self._log(
                "OK",
                "config.php partiel écarté; l'installation neuve peut reprendre."
            )

        if config_exists and cfg_php.is_file():
            rc, out = self._run(
                [php, str(cfg_php), "--name=version", "--no-eol"],
                cwd=root,
                check=False,
            )
            if rc == 0 and out.strip():
                self._log("SKIP", f"Moodle déjà installé. Version DB: {out.strip()}")
            else:
                raise InstallError(
                    "config.php existe et la DB contient des données, "
                    "mais Moodle ne peut pas lire correctement sa DB. "
                    "Arrêt de sécurité."
                )
        else:
            self._log("INFO", f"Aucun config.php racine actif: {root / 'config.php'}")
            self._log(
                "INFO",
                "Installation neuve/reprise détectée; lancement de admin/cli/install.php si la DB est vide."
            )
            if table_count > 0:
                raise InstallError(
                    f"La DB {dbname} contient déjà {table_count} table(s), mais aucun config.php Moodle n'est actif.\n"
                    "État partiel non vide détecté: l'outil s'arrête pour ne rien écraser."
                )

            self._log("INFO", "DB vide + core prêt: lancement de l'installation Moodle 5.2.")

            args = [
                php, str(install_php),
                "--non-interactive",
                "--agree-license",
                f"--wwwroot={wwwroot}",
                f"--dataroot={dataroot}",
                f"--dbtype={VALID_DBTYPE}",
                f"--dbhost={dbhost}",
                f"--dbname={dbname}",
                f"--dbuser={dbuser}",
                f"--dbpass={db_pass}",
                "--prefix=mdl_",
                f"--fullname={self.var_fullname.get().strip() or 'UCKK Local'}",
                f"--shortname={self.var_shortname.get().strip() or 'UCKK'}",
                f"--adminuser={adminuser}",
                f"--adminpass={moodle_admin_pass}",
                "--lang=fr",
            ]
            self._run(
                args,
                cwd=root,
                redact=(db_pass, moodle_admin_pass),
                check=True,
            )
            self._log("OK", "Installation Moodle 5.2 terminée.")

        # Vérification finale utile, pas une étape manuelle.
        info = self._read_version(root)
        self._log(
            "OK",
            f"Core final: release={info.get('release')} branch={info.get('branch')} maturity={info.get('maturity')}"
        )

        if cfg_php.is_file():
            rc, out = self._run(
                [php, str(cfg_php), "--name=version", "--no-eol"],
                cwd=root,
                check=False,
            )
            if rc == 0:
                self._log("OK", f"DB Moodle finale: version={out.strip()}")

        self._save_state()

        self._phase("TERMINÉ")
        self._log("OK", "Moodle 5.2 local est prêt.")
        self._log("INFO", f"Admin Moodle: {adminuser}")
        self._log("INFO", f"Mot de passe admin: variable ENV {ENV_MOODLE_ADMIN_PASSWORD}")
        self._log("INFO", "Prochaine opération: synchroniser UCKK/UCC/Math via Ops Console.")

        if self.var_launch_ops.get():
            self._log("INFO", "Lancement automatique de l'Ops Console...")
            self.action_launch_ops()

    # --------------------------------------------------------------- ops

    def action_launch_ops(self):
        ops = Path(self.var_ops.get().strip())
        candidates = [
            ops / "UCKK_Ops_Console_RUN_clean.bat",
            ops / "UCKK_Ops_Console_RUN.bat",
            ops / "START_UCKK_OPS_CONSOLE.ps1",
        ]

        for p in candidates:
            if not p.exists():
                continue
            self._log("INFO", f"Lancement Ops Console: {p}")
            if p.suffix.lower() == ".bat":
                os.startfile(str(p))
            else:
                pwsh = self._which("pwsh.exe", "pwsh")
                if not pwsh:
                    raise InstallError("PowerShell 7 (pwsh.exe) introuvable.")
                subprocess.Popen(
                    [pwsh, "-NoLogo", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", str(p)],
                    cwd=str(ops),
                )
            self._log("OK", "Ops Console lancée.")
            return

        raise InstallError(f"Aucun lanceur Ops Console trouvé dans {ops}")


if __name__ == "__main__":
    App().mainloop()
