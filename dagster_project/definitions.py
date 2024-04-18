from dagster import asset, Definitions


@asset
def hello():
    return 'Hello'


definitions = Definitions(
    assets=[hello]
)
