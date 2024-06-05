from fastapi import FastAPI, File, UploadFile, Form, HTTPException
from pydantic import BaseModel
import requests
import json
from urllib.parse import unquote
import logging
import os
from dotenv import load_dotenv

# 加载环境变量
load_dotenv()

# 配置日志
logging.basicConfig(level=logging.INFO,
                    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s")
logger = logging.getLogger(__name__)

app = FastAPI()

UPLOAD_MEDIA_URL = os.getenv(
    "UPLOAD_MEDIA_URL", "https://oapi.dingtalk.com/media/upload")


class UploadResponse(BaseModel):
    status_code: int
    response_text: dict


@app.post("/uploadmedia/", response_model=UploadResponse)
async def upload_file(media: UploadFile = File(...), access_token: str = Form(...), type: str = Form(...)):
    try:
        # 读取文件内容
        file_content = await media.read()
        # 发送文件内容到钉钉上传媒体文件接口
        upload_media_url = f"{UPLOAD_MEDIA_URL}?access_token={access_token}&type={type}"
        decoded_medianame = unquote(media.filename)
        logger.info(f"decoded_filename: {decoded_medianame}")
        files = {"media": (decoded_medianame, file_content,
                           media.content_type)}
        response = requests.post(upload_media_url, files=files)
        response.raise_for_status()

        # 解析钉钉API的响应
        data = response.json()
        logger.info(f"status_code: {response.status_code}")
        if response.status_code != 200:
            # 如果响应中有错误，返回错误信息
            logger.error(
                f"RequestException: {data.get('errmsg', 'Unknown error occurred')}")
            raise HTTPException(status_code=response.status_code, detail=data.get(
                "errmsg", "Unknown error occurred"))
        logger.info(f"response.text: {response.text}")
        return UploadResponse(
            status_code=response.status_code,
            response_text=json.loads(response.text),
        )

    except requests.RequestException as e:
        # 处理请求异常
        logger.error(f"RequestException: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))
    except Exception as e:
        # 处理其他异常
        logger.error(f"Exception: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=int(os.getenv("FASTAPI_PORT", 8000)))
