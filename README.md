# ecommerce-data-analytics

> **Como uma operação de e-commerce pode melhorar seu desempenho comercial e a
> satisfação dos clientes a partir dos dados de vendas, pagamentos e entregas?**

Análise de ~100 mil pedidos de um marketplace brasileiro (dataset Olist,
2016–2018), do dado bruto ao dashboard: perfilagem, limpeza, exploração,
camada analítica em SQL e visualização em Power BI.

## Estrutura

```
ecommerce-data-analytics/
├── data/
│   ├── raw/                 # 9 CSVs originais da Olist (fonte da verdade)
│   └── processed/           # tabelas limpas (parquet/csv/sqlite) — regeneráveis
├── docs/
│   ├── business_problem.md      # pergunta, hipóteses e KPIs
│   ├── data_dictionary.md       # dicionário de dados tabela a tabela
│   └── data_quality_report.md   # problemas encontrados e tratamento
├── notebooks/
│   ├── 01_data_profiling.ipynb       # inventário e qualidade dos dados
│   └── 02_exploratory_analysis.ipynb # EDA por hipótese (H1–H5)
├── sql/
│   ├── 01_create_tables.sql      # schema PostgreSQL + carga
│   ├── 02_quality_checks.sql     # verificações de integridade
│   ├── 03_business_analysis.sql  # análises por hipótese
│   └── 04_views.sql              # views para o dashboard
├── src/
│   ├── load_data.py     # carrega data/raw/ em DataFrames
│   ├── clean_data.py    # regras de limpeza → data/processed/
│   └── export_data.py   # exporta p/ CSV e SQLite (Power BI)
├── tests/
│   └── test_data_quality.py  # pytest espelhando 02_quality_checks.sql
├── powerbi/
│   └── screenshots/     # imagens do dashboard
├── requirements.txt
└── README.md
```

## Como rodar

```bash
# 1. Ambiente
python -m venv .venv && source .venv/bin/activate   # Windows: .venv\Scripts\activate
pip install -r requirements.txt

# 2. Qualidade dos dados brutos
pytest tests/ -v

# 3. Limpeza e exportação (gera data/processed/)
python -m src.clean_data
python -m src.export_data

# 4. Notebooks de perfilagem e EDA
jupyter lab notebooks/
```

Opcional (camada SQL): crie o banco com `psql -f sql/01_create_tables.sql` e
rode `02_quality_checks.sql` e `03_business_analysis.sql`; as views de
`04_views.sql` alimentam o Power BI (ou use o SQLite gerado pelo passo 3).

## KPIs acompanhados

- Receita total e mensal • Ticket médio
- Tempo médio de entrega • % de pedidos atrasados
- Nota média de avaliação • NPS aproximado

## Documentação

- [Problema de negócio e hipóteses](docs/business_problem.md)
- [Dicionário de dados](docs/data_dictionary.md)
- [Relatório de qualidade](docs/data_quality_report.md)

## Fonte dos dados

[Olist Brazilian E-commerce Dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
(Kaggle) — licença de uso conforme definida pela fonte.
