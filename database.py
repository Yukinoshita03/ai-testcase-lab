from pathlib import Path
from sqlalchemy import create_engine, event

PROJECT_DIR = Path(__file__).resolve().parent
DATA_DIR = PROJECT_DIR / "data"
DATABASE_PATH = DATA_DIR / "app.db"
SCHEMA_PATH = PROJECT_DIR / "sql" / "schema.sql"

engine = create_engine(
    f"sqlite+pysqlite:///{DATABASE_PATH}",
    echo=True,
)


@event.listens_for(engine, "connect")
def enable_foreign_keys(dbapi_connection, connection_record):
    cursor = dbapi_connection.cursor()
    try:
        cursor.execute("PRAGMA foreign_keys = ON")
    finally:
        cursor.close()


def init_db():
    schema_sql = SCHEMA_PATH.read_text(encoding="utf-8")
    DATA_DIR.mkdir(parents=True, exist_ok=True)

    connection = engine.raw_connection()
    try:
        # SQLite executescript 支持多条 SQL，也能正确处理注释和字符串中的分号。
        # 显式 BEGIN，让整个初始化脚本在同一个事务中执行。
        connection.driver_connection.executescript("BEGIN;\n" + schema_sql)
        connection.commit()
    except BaseException:
        connection.rollback()
        raise
    finally:
        connection.close()

def close_db():
    engine.dispose()
if __name__ == "__main__":
    init_db()
    print("数据库初始化完成")
