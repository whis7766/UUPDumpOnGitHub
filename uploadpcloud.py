from datetime import datetime
import os
from zoneinfo import ZoneInfo
from fundrive.drives.pcloud import PCloudDrive


class CustomPCloudDrive(PCloudDrive):
    def delete_all_contents(self):
        def delete_recursive(fid):
            for file in self.get_file_list(fid):
                self.delete(file.fid)
            for folder in self.get_dir_list(fid):
                delete_recursive(folder.fid)
                self.delete(folder.fid)

        delete_recursive("0")


if __name__ == "__main__":
    retry = lambda func, max_retries=5: any(func() for _ in range(max_retries)) or exit(
        1
    )
    drive = CustomPCloudDrive()

    retry(lambda: drive.login(auth_token=os.environ["PCLOUD_auth_token"]))
    drive.delete_all_contents()
    drive.clear_recycle()

    retry(
        lambda: drive.upload_file(
            "../uuprun/output.iso",
            "0",
            datetime.now(ZoneInfo("Asia/Shanghai")).strftime("%m%d%H%M") + ".iso",
        )
    )
