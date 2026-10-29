# Torna o pacote do projeto importável nos testes (`from src.load_data import ...`)
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
