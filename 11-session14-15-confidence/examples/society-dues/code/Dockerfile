# The image the pipeline builds once and deploys (az acr build). Same image, every environment.
FROM python:3.12-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir fastapi==0.143.0 uvicorn==0.53.0
COPY dues ./dues
RUN useradd --create-home app
USER app
ENV PORT=8000
EXPOSE 8000
CMD ["sh", "-c", "uvicorn dues.api:app --host 0.0.0.0 --port ${PORT}"]
