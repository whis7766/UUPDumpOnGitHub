from datetime import datetime
import os
from zoneinfo import ZoneInfo
from fundrive.drives.pcloud import PCloudDrive
from fundrive.core.exceptions import retry_on_error, NetworkError, RateLimitError
import nltsecret

if __name__ == "__main__":
    local_file = "../uuprun/output.iso"
    # nltsecret.write_secret(
    #     os.environ["PCLOUD_USERNAME"], "fundrive", "pcloud", "username"
    # )
    # nltsecret.write_secret(
    #     os.environ["PCLOUD_PASSWORD"], "fundrive", "pcloud", "password"
    # )
    drive = PCloudDrive()
    drive.login(
            auth_token=os.environ["PCLOUD_auth_token"]
        )
    # drive.login()
    drive.delete_all_contents()
    drive.clear_recycle()
    drive.upload_file(
        local_file,
        "0",
        filename=datetime.now(ZoneInfo("Asia/Shanghai")).strftime("%y%m%d%H%M")
        + ".iso",
    )
