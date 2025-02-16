import os
from dotenv import load_dotenv
import pandas as pd
from sqlalchemy import create_engine

load_dotenv()
db_user = os.getenv('DB_USER')
db_password = os.getenv('DB_PASSWORD')
db_host = os.getenv('DB_HOST')
db_port = os.getenv('DB_PORT')
db_name = os.getenv('DB_NAME')


connection_string = f'postgresql+psycopg2://{db_user}:{db_password}@{db_host}:{db_port}/{db_name}'
engine = create_engine(connection_string)


excel_file = 'customer_and_transaction.xlsx'

def export_sheet_to_sql(sheet, table):
    df = pd.read_excel(excel_file, sheet_name=sheet)
    df.columns = [col.strip().lower() for col in df.columns]
    df.to_sql(table, engine, if_exists='replace', index=False)
    print(f"WB: {excel_file},\t WS: {sheet} \t imported to {table}.")

export_sheet_to_sql('customer', 'raw_customer')
export_sheet_to_sql('transaction', 'raw_transaction')