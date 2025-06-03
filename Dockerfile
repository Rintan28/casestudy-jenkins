FROM python:3.9
WORKDIR /app
RUN pip install flask
# Install Helm
RUN curl -fsSL https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
COPY . .
CMD ["python", "app.py"]
