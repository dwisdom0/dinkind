# sort of based on
# https://github.com/dagster-io/dagster/blob/de7d0f07115146a19ca94f3eb0f4924ceded62dc/python_modules/automation/automation/docker/images/user-code-example/Dockerfile

FROM bitnami/python:3.11

COPY dagster_project /opt/dagster_project

WORKDIR /opt/dagster_project

RUN pip install -U pip && \
    pip install --no-cache-dir -r requirements.txt



