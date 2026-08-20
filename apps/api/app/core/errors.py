from __future__ import annotations


class DoclyvoError(Exception):
    code: str = "internal_error"
    status_code: int = 500

    def __init__(self, message: str) -> None:
        self.message = message
        super().__init__(message)


class FileTooLargeError(DoclyvoError):
    code = "file_too_large"
    status_code = 413

    def __init__(self, max_size_mb: int) -> None:
        super().__init__(f"File exceeds the {max_size_mb}MB upload limit.")


class UnsupportedFormatError(DoclyvoError):
    code = "unsupported_format"
    status_code = 415


class InvalidRequestError(DoclyvoError):
    code = "invalid_request"
    status_code = 400


class ProcessingFailedError(DoclyvoError):
    code = "processing_failed"
    status_code = 422

    def __init__(self) -> None:
        super().__init__("The document could not be processed. It may be corrupted or encrypted.")


class PersistenceError(DoclyvoError):
    code = "persistence_failed"
    status_code = 503

    def __init__(self) -> None:
        super().__init__("The signed document could not be recorded. Please try again.")
