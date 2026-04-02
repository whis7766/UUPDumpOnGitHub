from datetime import datetime
import os
from zoneinfo import ZoneInfo
from fundrive.drives.pcloud import PCloudDrive
from fundrive.core.exceptions import retry_on_error, NetworkError, RateLimitError
import nltsecret

RETRY_CONFIG = {
    "max_retries": 10,
    "delay": 1.0,
    "backoff_factor": 2.0,
    "exceptions": (Exception,),
}


class PCloudDriveWithRetry(PCloudDrive):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        for method in [
            "login",
            "delete",
            "clear_recycle",
            "upload_file",
            "get_file_list",
            "get_dir_list",
        ]:
            if hasattr(self, method):
                setattr(
                    self, method, retry_on_error(**RETRY_CONFIG)(getattr(self, method))
                )

    def delete_all_contents(self):
        def delete_recursive(fid: str):
            for file in self.get_file_list(fid):
                self.delete(file.fid)
            for dir in self.get_dir_list(fid):
                delete_recursive(dir.fid)
                self.delete(dir.fid)

        delete_recursive("0")


if __name__ == "__main__":
    local_file = "../uuprun/output.iso"
    nltsecret.write_secret(
        os.environ["PCLOUD_USERNAME"], "fundrive", "pcloud", "username"
    )
    nltsecret.write_secret(
        os.environ["PCLOUD_PASSWORD"], "fundrive", "pcloud", "password"
    )
    drive = PCloudDriveWithRetry()
    drive.login()
    drive.delete_all_contents()
    drive.clear_recycle()
    drive.upload_file(
        local_file,
        "0",
        filename=datetime.now(ZoneInfo("Asia/Shanghai")).strftime("%y%m%d%H%M")
        + ".iso",
    )
