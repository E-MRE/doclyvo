from __future__ import annotations

import secrets
from pathlib import Path

import pikepdf

from app.core.errors import ProcessingFailedError, UnsupportedFormatError


class ProtectService:
    def protect(
        self,
        input_path: Path,
        output_path: Path,
        password: str,
        no_print: bool,
        no_copy: bool,
        no_edit: bool,
    ) -> None:
        permissions = pikepdf.Permissions(
            accessibility=True,
            extract=not no_copy,
            modify_annotation=not no_edit,
            modify_assembly=not no_edit,
            modify_form=not no_edit,
            modify_other=not no_edit,
            print_lowres=not no_print,
            print_highres=not no_print,
        )
        owner_password = secrets.token_urlsafe(18)
        encryption = pikepdf.Encryption(owner=owner_password, user=password, allow=permissions)

        try:
            with pikepdf.open(input_path) as pdf:
                pdf.save(output_path, encryption=encryption)
        except pikepdf.PasswordError as exc:
            raise UnsupportedFormatError("The PDF is already password-protected.") from exc
        except pikepdf.PdfError as exc:
            raise ProcessingFailedError() from exc
