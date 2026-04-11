# Financial Data Pipeline - Complete Architecture Overview

**Last Updated**: April 10, 2026 (Analysis Engine Redesign Applied)  
**Status**: Production-Ready Multi-Component System with NEW Markov→MC→LLM→Portfolio Pipeline

> ⚠️ **IMPORTANT**: This document reflects the **REDESIGNED analysis engine** implemented on April 10, 2026. The old multi-model approach (Linear, CNN, XGBoost scorers) has been replaced with a sophisticated regime-aware pipeline featuring Markov chain detection, Monte Carlo simulation, LLM asset filtering, and risk-profile-based portfolio construction. See **REDESIGN_EXECUTIVE_SUMMARY.md** for a quick before/after comparison.

---

## 🎯 Project Purpose

A comprehensive **Robo-Advisory and Financial Analysis platform** designed around two core business processes:
1. **Robo-Advisory Client Onboarding**: Users create accounts, answer a targeted questionnaire, and are assigned a definitive Risk-Profile. The system then determines the ideal investment-type split (risky vs. safe, long-term vs. short-term) and uses the LLM engine to generate a bespoke initial portfolio based on their profile.
2. **Ongoing Portfolio Management (Investment Shifting)**: The system actively manages existing portfolios, continuously evaluating alternative assets. It dynamically shifts investments and rebalances capital when the LLM identifies better market opportunities or when the underlying market regime changes.
3. **Data Aggregation & Infrastructure**: Powers the advisory engine by continuously collecting market data via ETL pipelines and analyzing it using Markov chains and Monte Carlo simulations.

---

## 🏗️ System Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                     FINANCIAL DATA PIPELINE ECOSYSTEM                    │
└─────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────┐
│ LAYER 1: DATA INGESTION (financial_data_aggregator)                      │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                           │
│  External Sources:                                                       │
│  ├─ Yahoo Finance (Stock OHLCV)          → Stock ETL Pipeline           │
│  ├─ CoinGecko API (Crypto prices)        → Crypto ETL Pipeline          │
│  ├─ FRED API (Economic indicators)       → Economic ETL Pipeline        │
│  ├─ Alpha Vantage (Alternative stock)    → Stock Alternative Source    │
│  ├─ Commodity Futures (Oil, Gold)        → Commodity ETL Pipeline       │
│  └─ Bond/Treasury Data (Yahoo, FRED)     → Bond ETL Pipeline            │
│                                                                           │
│  ↓ UNIFIED PIPELINE ORCHESTRATION                                        │
│                                                                           │
│  SQL Star Schema Database (SQLite/PostgreSQL):                           │
│  ├─ FACT TABLES:                                                        │
│  │  ├─ fact_stock_price         (OHLCV daily data)                      │
│  │  ├─ fact_crypto_price        (Crypto prices, market cap)             │
│  │  ├─ fact_bond_price          (Treasury yields, bond prices)          │
│  │  ├─ fact_commodity_price     (Futures and spot prices)               │
│  │  ├─ fact_economic_indicator  (GDP, inflation, employment, etc.)     │
│  │  ├─ fact_company_metrics     (P/E, debt/equity, ROE, ROA)            │
│  │  └─ fact_sec_filing          (SEC 10-K/10-Q filings)                 │
│  │                                                                       │
│  └─ DIMENSION TABLES:                                                   │
│     ├─ dim_company             (500+ US stocks across sectors)          │
│     ├─ dim_crypto_asset        (50+ cryptocurrencies)                   │
│     ├─ dim_bond                (Treasury bonds by maturity)             │
│     ├─ dim_issuer              (Bond issuers, ratings)                  │
│     ├─ dim_commodity           (Oil, Gold, Metals, Agriculture)         │
│     ├─ dim_economic_indicator  (15+ key economic series)                │
│     ├─ dim_date                (Calendar attributes for time series)    │
│     ├─ dim_exchange            (NYSE, NASDAQ, etc.)                     │
│     └─ dim_data_source         (API sources, refresh schedules)         │
│                                                                           │
└──────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────┐
│ LAYER 2: ANALYSIS ENGINE (model_regime_comparison) - REDESIGNED           │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                           │
│  DATA LOADING PHASE                                                      │
│  └─ Queries financial_data_aggregator SQLite DB                         │
│     ├─ Loads 250+ stocks across 5 sectors                               │
│     ├─ Loads 50+ crypto assets                                          │
│     ├─ Loads bonds and commodities                                      │
│     └─ Loads economic indicators and company metadata                   │
│                                                                           │
│  ↓ PHASE 1: MARKOV CHAIN REGIME DETECTION                                │
│                                                                           │
│  Hidden Markov Model Analysis:                                           │
│  ├─ Trains on 5-year historical returns                                 │
│  ├─ Detects 5 hidden market states (learned order):                     │
│  │  ├─ Bear Regime (high volatility, negative drift)                    │
│  │  ├─ Sideways Regime (low drift, moderate volatility)                 │
│  │  ├─ Bull Regime (positive drift, moderate volatility)                │
│  │  ├─ Volatility Spike (extreme volatility, fast transitions)          │
│  │  └─ Recovery Regime (stabilizing, mean reversion)                    │
│  │                                                                       │
│  Output: MarkovRegimeState dataclass                                     │
│  ├─ current_regime: str (detected market state)                         │
│  ├─ regime_probability: 0-1 (confidence in detection)                   │
│  ├─ transition_matrix: 5×5 (state transition probabilities)             │
│  ├─ probability_next_regime: dict (next state probabilities)            │
│  ├─ time_in_regime: timedelta (duration in current state)               │
│  └─ regime_features: dict (entropy, persistence, etc.)                  │
│                                                                           │
│  ↓ PHASE 2: REGIME-AWARE MONTE CARLO SIMULATION                          │
│                                                                           │
│  Stochastic Forward Simulation:                                          │
│  ├─ Filters historical returns by detected regime                       │
│  ├─ Simulates 10,000+ forward price paths per asset                     │
│  ├─ Uses regime-specific return distributions                           │
│  ├─ Compounds returns over analysis horizon (252 trading days)          │
│  │                                                                       │
│  Output: MonteCarloMetrics dataclass per asset                           │
│  ├─ ticker, regime, n_simulations                                       │
│  ├─ mean_return, median_return (central tendency)                       │
│  ├─ var_95, var_99 (Value at Risk at 95%/99% confidence)                │
│  ├─ es_95, es_99 (Expected Shortfall at 95%/99%)                        │
│  ├─ prob_loss (probability of negative return)                          │
│  ├─ prob_positive (probability of positive return)                      │
│  ├─ ci_95_lower/upper, ci_99_lower/upper (confidence intervals)         │
│  ├─ skewness, kurtosis (distribution shape)                             │
│  ├─ regime_suitability: dict (Bull/Bear/Sideways fit scores)            │
│  └─ simulated_returns: np.ndarray (10,000+ realized paths)              │
│                                                                           │
│  Risk Metrics Explained:                                                 │
│  ├─ VaR(95%): Max loss in best 95% of scenarios                         │
│  ├─ VaR(99%): Max loss in best 99% of scenarios                         │
│  ├─ ES(95%): Average of worst 5% outcomes                               │
│  └─ ES(99%): Average of worst 1% outcomes (tail risk)                   │
│                                                                           │
│  ↓ PHASE 3: LLM-DRIVEN ASSET FILTERING                                   │
│                                                                           │
│  Intelligent Asset Recommendation:                                       │
│  ├─ Sends Monte Carlo results to local LLM (Ollama)                     │
│  ├─ Prompt includes:                                                    │
│  │  ├─ Asset metrics (mean, VaR, ES, prob_loss)                         │
│  │  ├─ Current market regime (type, confidence, time in regime)         │
│  │  ├─ Risk profile constraints (VaR target, allocation %)              │
│  │  └─ Historical regime suitability                                    │
│  ├─ LLM returns semantic scoring (0-1 per asset)                        │
│  └─ Focuses on assets that fit regime + risk profile                    │
│                                                                           │
│  ↓ PHASE 4: RISK-PROFILE-BASED PORTFOLIO CONSTRUCTION                    │
│                                                                           │
│  5 Predefined Risk Profiles:                                             │
│  ├─ VERY_CONSERVATIVE: VaR(95%) target 2%, ES(95%) 1%                   │
│  │  └─ 10% stocks, 80% bonds, 5% commodities, 5% cash                  │
│  ├─ CONSERVATIVE: VaR(95%) target 5%, ES(95%) 3%                        │
│  │  └─ 20% stocks, 60% bonds, 15% commodities, 5% cash                 │
│  ├─ MODERATE: VaR(95%) target 10%, ES(95%) 6%                           │
│  │  └─ 40% stocks, 35% bonds, 20% crypto, 5% cash                      │
│  ├─ AGGRESSIVE: VaR(95%) target 15%, ES(95%) 10%                        │
│  │  └─ 60% stocks, 15% bonds, 20% crypto, 5% cash                      │
│  └─ VERY_AGGRESSIVE: VaR(95%) target 25%, ES(95%) 18%                   │
│     └─ 70% stocks, 5% bonds, 25% crypto, 0% cash                       │
│                                                                           │
│  Portfolio Construction Algorithm:                                       │
│  ├─ Allocates budget by asset class per profile                         │
│  ├─ Selects top N assets per tier (by LLM score)                        │
│  ├─ Sizes positions equally within tier                                 │
│  ├─ Validates portfolio vs profile constraints:                         │
│  │  ├─ Portfolio VaR(95%) ≤ profile target                              │
│  │  ├─ Max position size ≤ 5%                                           │
│  │  ├─ Max sector concentration ≤ 20%                                   │
│  │  ├─ Top 5 positions ≤ 30% of portfolio                               │
│  │  └─ Min 10 positions for diversification                             │
│  │                                                                       │
│  Output: PortfolioAllocation dataclass                                   │
│  ├─ positions: list[PortfolioPosition] (detailed holdings)              │
│  ├─ cash: float (uninvested amount)                                     │
│  ├─ total_value: float (portfolio NAV)                                  │
│  ├─ risk_profile_type: enum (which profile used)                        │
│  ├─ portfolio_expected_mean/var/es (weighted aggregate metrics)         │
│  ├─ allocation_by_type/sector: dict (breakdown)                         │
│  ├─ regime_at_construction: str (market regime used)                    │
│  ├─ llm_recommendations_used: list (which assets LLM scored)            │
│  └─ validation result: bool (passes all constraints)                    │
│                                                                           │
│  ↓ PHASE 5: VALIDATION & AUDIT TRAIL                                     │
│                                                                           │
│  Comprehensive Checks:                                                   │
│  ├─ VaR compliance vs risk profile                                      │
│  ├─ Diversification (min positions, max concentration)                  │
│  ├─ Sector rotation compliance                                          │
│  ├─ Cash allocation sufficiency                                         │
│  └─ Regime fit confirmation                                             │
│                                                                           │
│  ↓ PHASE 6: EXPORT TO TRADING SIMULATOR                                  │
│                                                                           │
│  Integration:                                                            │
│  ├─ POST /portfolios with full allocation                               │
│  ├─ Trading Simulator executes all positions                            │
│  ├─ Receives portfolio_id for tracking                                  │
│  └─ Metrics (NAV, P&L, regime changes) tracked daily                    │
│                                                                           │
│  ↓ PHASE 7: RESULTS PERSISTENCE & LOGGING                                │
│                                                                           │
│  Output Artifacts:                                                       │
│  ├─ metadata.json (execution_id, dates, regime state)                   │
│  ├─ execution_log.txt (phase-by-phase trace)                            │
│  ├─ portfolio.json (full PortfolioAllocation serialized)                 │
│  ├─ mc_results.pkl (MonteCarloMetrics for all assets)                   │
│  └─ markov_state.pkl (MarkovRegimeState for audit)                      │
│                                                                           │
└──────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────┐
│ LAYER 3: EXECUTION & SIMULATION (Trading_Simulator)                      │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                           │
│  BACKEND (FastAPI, Python)                           FRONTEND (React)   │
│                                                                           │
│  ├─ 14+ REST API Endpoints                     ├─ Dashboard (landing)   │
│  ├─ Order Engine (buy/sell execution)          ├─ Portfolio Details    │
│  ├─ Portfolio Manager (multiple portfolios)    ├─ Trading Interface    │
│  ├─ Performance Calculator (metrics)           ├─ Order Workflow      │
│  ├─ Price Lookup (real-time pricing)           ├─ Analytics Dashboard │
│  │                                              ├─ Model Comparison    │
│  └─ Model Integration Layer                    └─ Creation Wizard      │
│     └─ Accepts trades from model_regime        │                       │
│        comparison via API                      └─ Recharts Visualize   │
│                                                                         │
│  SQLAlchemy ORM (SQLite Database):                                      │
│  ├─ Portfolio (model-managed vs manual)                                │
│  ├─ Position (holdings with entry price/qty)                           │
│  ├─ Transaction (order history with fees)                              │
│  ├─ OrderHistory (bid/ask data for analysis)                           │
│  ├─ PriceQuote (current prices from lookup)                            │
│  ├─ User (authentication, admin access)                                │
│  ├─ TradeLog (model execution trail)                                   │
│  ├─ ModelMetrics (model performance cache)                             │
│  └─ AuditLog (compliance/audit trail)                                  │
│                                                                         │
│  Two Portfolio Management Modes:                                        │
│  ├─ AUTOMATED (Model-Driven):                                          │
│  │  ├─ Models from Layer 2 execute trades via API                      │
│  │  ├─ POST /orders/{portfolio_id}/buy|sell                            │
│  │  ├─ Automatic position sizing (Kelly Criterion)                     │
│  │  ├─ No human intervention                                           │
│  │  └─ Real-time portfolio updates                                     │
│  │                                                                     │
│  └─ MANUAL (User-Driven):                                              │
│     ├─ Human trader uses GUI to create orders                          │
│     ├─ 3-step order flow: Form → Confirm → Execute                     │
│     ├─ Paper trading (no real money)                                   │
│     ├─ Full position tracking and analytics                            │
│     └─ Risk metrics computed in real-time                              │
│                                                                         │
│  Performance Tracking:                                                  │
│  ├─ NAV (Net Asset Value) history                                      │
│  ├─ Sharpe/Sortino ratios                                              │
│  ├─ Drawdown analysis                                                  │
│  ├─ Volatility measurements                                            │
│  ├─ Value at Risk (95%/99% confidence)                                 │
│  ├─ Individual holding P&L                                             │
│  ├─ Transaction costs and fees                                         │
│  └─ Sector allocation pie charts                                       │
│                                                                         │
└──────────────────────────────────────────────────────────────────────────┘
```

---

## 📊 Data Flow End-to-End (NEW REDESIGNED PIPELINE)

```
EXTRACTION PHASE
│
├─ Financial_Data_Aggregator runs scheduled ETL jobs
│  ├─ Crypto ETL: Pulls BTC, ETH, 50+ from CoinGecko
│  ├─ Stock ETL: Pulls OHLCV from Yahoo Finance
│  ├─ Bond ETL: Pulls Treasury yields from FRED
│  ├─ Economic ETL: Pulls indicators (GDP, inflation, employment)
│  ├─ Commodity ETL: Pulls futures and spot prices
│  └─ Each includes data quality validation & error handling
│
├─ All data loaded into Star Schema (Fact + Dimension tables)
└─ Database state: 100,000+ price records across assets

PHASE 1: MARKOV CHAIN REGIME DETECTION
│
├─ Load 5-year historical returns from aggregator database
├─ Train Hidden Markov Model (5 hidden states)
├─ Learn state transition probabilities
├─ Detect current market regime with confidence
└─ Output: MarkovRegimeState (regime type, probability, transitions, time in regime)

PHASE 2: REGIME-AWARE MONTE CARLO SIMULATION
│
├─ For each asset in universe:
│  ├─ Filter historical returns by detected regime
│  ├─ Simulate 10,000+ forward price paths
│  ├─ Compound returns over 252-day horizon
│  ├─ Compute metrics (mean, median, VaR(95%), VaR(99%), ES(95%), ES(99%))
│  ├─ Calculate confidence intervals and distribution shape
│  └─ Score regime suitability (Bull/Bear/Sideways/Volatility/Recovery fit)
│
└─ Output: MonteCarloMetrics per asset (risk metrics, regime suitability)

PHASE 3: LLM-DRIVEN ASSET FILTERING
│
├─ Query local LLM (Ollama) with:
│  ├─ Monte Carlo results (mean, VaR, ES, prob_loss)
│  ├─ Current market regime info
│  ├─ Risk profile constraints
│  └─ Asset universe details
├─ LLM returns semantic scoring (0-1 confidence) for each asset
└─ Output: Dict[ticker, score] - prioritized asset list

PHASE 4: ROBO-ADVISORY ONBOARDING & PORTFOLIO CONSTRUCTION
│
├─ User completes onboarding questionnaire; system assigns risk profile
├─ Portfolio constructor determines investment-type split (risky/safe, short/long-term)
├─ Allocates budget across asset classes per profile
├─ Selects top-N assets per tier using LLM scores
│  ├─ Sizes positions equally within tier
│  ├─ Validates against all constraints:
│  │  ├─ Portfolio VaR(95%) ≤ profile target
│  │  ├─ Max position ≤ 5% of portfolio
│  │  ├─ Max sector ≤ 20%
│  │  ├─ Top-5 ≤ 30% total
│  │  └─ Min 10 positions for diversification
│  └─ Returns validated PortfolioAllocation
│
└─ Output: Full allocation with positions, expected return/VaR/ES, audit trail

PHASE 5: VALIDATION & AUDIT
│
├─ Verify all constraints met
├─ Compute portfolio-level risk metrics
├─ Confirm regime fit
├─ Generate execution log
└─ Save metadata for reproducibility

PHASE 6: EXPORT TO TRADING SIMULATOR
│
├─ POST /portfolios to Trading Simulator API
├─ Trading Simulator creates portfolio and executes all positions
├─ Receives portfolio_id for tracking
└─ Both modes supported:
    ├─ AUTOMATED: Direct API integration (this pipeline)
    └─ MANUAL: User creates via UI

PHASE 7: ONGOING PORTFOLIO MANAGEMENT (INVESTMENT SHIFTING)
│
├─ Daily: Monitor existing portfolio NAV, market regime changes, and new LLM scores
├─ Track portfolio drift against the user's assigned risk profile constraints
├─ Dynamic Rebalancing & Investment Shifting:
│  ├─ Shift investments if the LLM identifies assets with superior scores/opportunities
│  ├─ Rebalance capital allocation if the underlying market regime changes significantly
│  └─ Sell off assets that breach VaR targets and reinvest in safer assets
│
└─ All transactions and metrics persisted in Trading Simulator database
```

---

## 🔧 Key Technologies (Updated for Redesign)

| Component | Layer | Framework | Key Libraries | Language |
|-----------|-------|-----------|-----------------|----------|
| **Financial_Data_Aggregator** | Ingestion | SQLAlchemy, Pandas | requests, yfinance, FRED API | Python |
| **Model_Regime_Comparison v2** | Analysis | **hmmlearn, numpy, pandas** | scikit-learn, Ollama client, loguru | Python |
| **Trading_Simulator Backend** | Execution | FastAPI, SQLAlchemy | requests, asyncio | Python |
| **Trading_Simulator Frontend** | UI | React 18, Vite, Recharts | Axios, TailwindCSS | JavaScript |

**NEW Pipeline Dependencies:**
- `hmmlearn` - Hidden Markov Model for regime detection
- `numpy` - Monte Carlo simulation calculations
- `requests` - LLM API calls to Ollama
- `loguru` - Structured logging throughout pipeline
- `pandas` - Data manipulation and analysis

---

## 📁 Directory Structure

```
/home/archy/Desktop/Server/FinancialData/
│
├── financial_data_aggregator/          # ETL Pipelines
│   ├── pipeline.py                     # Stock pipeline
│   ├── crypto_etl_pipeline.py          # Crypto pipeline
│   ├── bond_etl_pipeline.py            # Bond pipeline
│   ├── economic_etl_pipeline.py        # Economic indicators
│   ├── commodity_etl_pipeline.py       # Commodities
│   ├── unified_pipeline.py             # Orchestrator (runs all)
│   ├── src/
│   │   ├── extractors/                 # Data source adapters
│   │   ├── transformers/               # Data transformation logic
│   │   ├── loaders/                    # Database loading
│   │   ├── models/                     # SQLAlchemy ORM models (star schema)
│   │   └── utils/                      # Helpers (email, logging, validation)
│   ├── config/
│   │   └── pipeline_config.yaml        # Configuration (tickers, sources, etc)
│   ├── data/                           # SQLite database
│   ├── logs/                           # Pipeline execution logs
│   ├── requirements.txt                # Dependencies
│   └── tests/                          # Unit tests for each pipeline
│
├── model_regime_comparison/            # Analysis Engine (Redesigned Apr 2026)
│   ├── main.py                         # Entry point
│   ├── src/
│   │   ├── config/
│   │   │   └── config.py               # Pipeline configuration
│   │   │
│   │   ├── data/
│   │   │   └── data_loader.py          # Loads from aggregator DB
│   │   │
│   │   ├── regime/                     # PHASE 1: Markov Chain Detection
│   │   │   └── markov_chain_detector.py (551 lines)
│   │   │      ├─ MarkovChainRegimeDetector
│   │   │      ├─ fit(), detect_current_regime()
│   │   │      ├─ get_transition_matrix()
│   │   │      └─ filter_returns_by_regime()
│   │   │
│   │   ├── risk/                       # PHASE 2: Monte Carlo Simulation
│   │   │   └── enhanced_monte_carlo.py (437 lines)
│   │   │      ├─ MonteCarloSimulator
│   │   │      ├─ simulate_asset(), simulate_portfolio()
│   │   │      ├─ VaR(95%, 99%), ES(95%, 99%) metrics
│   │   │      └─ Regime suitability scoring
│   │   │
│   │   ├── advisory/                   # PHASE 3: LLM Asset Filtering
│   │   │   └── llm_asset_selector.py (182 lines)
│   │   │      ├─ LLMAssetSelector
│   │   │      ├─ Ollama integration
│   │   │      ├─ Semantic asset scoring
│   │   │      └─ Regime + risk profile aware
│   │   │
│   │   ├── portfolio/                  # PHASE 4: Risk-Based Construction
│   │   │   └── risk_profiles.py (637 lines)
│   │   │      ├─ 5 RiskProfileType enums
│   │   │      ├─ RiskProfileRegistry (VERY_CONSERVATIVE to VERY_AGGRESSIVE)
│   │   │      ├─ LLMPortfolioConstructor
│   │   │      ├─ constraint validation
│   │   │      └─ PortfolioAllocation dataclass
│   │   │
│   │   ├── analysis/                   # PHASE 5-7: Pipeline Orchestration
│   │   │   └── analysis_pipeline.py (483 lines)
│   │   │      ├─ AnalysisPipeline (main orchestrator)
│   │   │      ├─ 7-phase workflow
│   │   │      ├─ Validation & audit trail
│   │   │      └─ Results persistence
│   │   │
│   │   └── integrations/               # PHASE 6: Trading Simulator Export
│   │       └── trading_simulator_client.py (267 lines)
│   │          ├─ TradingSimulatorClient
│   │          ├─ create_portfolio()
│   │          ├─ execute_buy_order(), execute_sell_order()
│   │          ├─ rebalance_portfolio()
│   │          └─ get_portfolio_metrics()
│   │
│   ├── results/                        # Execution outputs
│   │   ├─ metadata.json               # Execution state
│   │   ├─ portfolio.json              # Portfolio allocation
│   │   ├─ execution_log.txt           # Phase traces
│   │   └─ mc_results.pkl              # Simulation outputs
│   │
│   ├── config/                         # Configuration files
│   ├── requirements.txt                # New: hmmlearn, requests, etc
│   ├── tests/                          # Unit tests (pending)
│   │
│   ├── DOCUMENTATION_INDEX.md          # **NEW**: Complete guide index
│   ├── REDESIGN_EXECUTIVE_SUMMARY.md   # **NEW**: What changed & why
│   ├── NEW_ENGINE_USAGE_GUIDE.md       # **NEW**: How to use (600+ lines)
│   ├── ANALYSIS_ENGINE_REDESIGN.md     # **NEW**: Full architecture (650+ lines)
│   ├── IMPLEMENTATION_SUMMARY.md       # **NEW**: What was built (400+ lines)
│   └── FILES_AND_STRUCTURE.md          # **NEW**: File reference (350+ lines)
│
├── Trading_Simulator/                  # Paper Trading Platform
│   ├── backend/                        # FastAPI REST API
│   │   ├── src/
│   │   │   ├── models/                 # SQLAlchemy ORM (9 tables)
│   │   │   ├── schemas/                # Pydantic validation
│   │   │   ├── services/               # Business logic
│   │   │   ├── routes/                 # API endpoints
│   │   │   └── utils/                  # Helpers
│   │   ├── main.py                     # FastAPI app
│   │   ├── requirements.txt            # Python dependencies
│   │   └── trading_simulator.db        # SQLite database
│   │
│   ├── frontend/                       # React UI
│   │   ├── src/
│   │   │   ├── components/             # 20+ React components
│   │   │   │   ├── Dashboard.jsx       # Landing page
│   │   │   │   ├── pages/              # Page components
│   │   │   │   ├── charts/             # Recharts visualizations
│   │   │   │   └── tables/             # Data display
│   │   │   ├── services/
│   │   │   │   └── api.js              # Axios client (14+ endpoints)
│   │   │   ├── App.jsx                 # Router config
│   │   │   └── main.jsx                # Entry point
│   │   ├── package.json                # Node dependencies
│   │   └── vite.config.js              # Vite build config
│   │
│   ├── docker-compose.yml              # Full stack deployment
│   └── [Documentation files]           # Phase completions, guides
│
└── [Documentation & Roadmaps]
    ├── PROJECT_ROADMAP_*.md
    ├── BAYESIAN_FRAMEWORK_ROADMAP_*.md
    └── [Various idea/enhancement documents]
```

---

## 🚀 How to Use Each Component

### 1. Financial Data Aggregator

**Setup:**
```bash
cd financial_data_aggregator
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
# Add API keys to .env
```

**Run All Pipelines:**
```bash
python unified_pipeline.py --all
```

**Run Specific Pipeline:**
```bash
python crypto_etl_pipeline.py --symbols BTC ETH
python bond_etl_pipeline.py --periods 10Y 30Y
python economic_etl_pipeline.py --indicators GDP UNRATE
```

**Output:** SQLite database with 100,000+ records across 9 fact tables


### 2. Model Regime Comparison (NEW REDESIGNED PIPELINE)

**Setup:**
```bash
cd model_regime_comparison
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
# Requirements: hmmlearn, numpy, pandas, scikit-learn, requests, loguru
```

**Start Ollama LLM (for asset filtering):**
```bash
# Terminal 1: Start Ollama server
ollama serve

# Terminal 2: Pull llama2 model
ollama pull llama2
```

**Run Full Analysis Pipeline:**
```bash
cd model_regime_comparison
python -c "
from src.analysis.analysis_pipeline import AnalysisPipeline
from src.portfolio.risk_profiles import RiskProfileType

pipeline = AnalysisPipeline()
result = pipeline.run(
    risk_profile=RiskProfileType.MODERATE,
    budget=100000,
    stock_universe=['AAPL', 'MSFT', 'GOOGL', ...],  # 250+ stocks
    force_retrain_markov=False,
    send_to_simulator=True
)
print(f'Portfolio created: {result.portfolio_allocation.total_value}')
"
```

**Outputs:**
- `results/metadata.json` - Execution state, regime, timestamps
- `results/portfolio.json` - Full portfolio allocation (positions, weights, metrics)
- `results/execution_log.txt` - Phase-by-phase trace (Markov→MC→LLM→Portfolio)
- `results/mc_results.pkl` - Monte Carlo metrics for all assets
- `results/markov_state.pkl` - Regime state for audit trail

**Key Features:**
- ✅ Markov chain detects current market regime
- ✅ Monte Carlo simulates 10,000 paths per asset
- ✅ Computes VaR(95%), VaR(99%), ES(95%), ES(99%)
- ✅ LLM intelligently filters assets by regime + risk fit
- ✅ 5 predefined risk profiles (VERY_CONSERVATIVE → VERY_AGGRESSIVE)
- ✅ Validates all constraints (VaR targets, diversification, concentration)
- ✅ Exports to Trading Simulator for execution


### 3. Trading Simulator

**Setup Backend:**
```bash
cd Trading_Simulator/backend
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python init_db.py  # Initialize database
```

**Run Backend:**
```bash
python main.py
# Backend runs on http://localhost:8001
# API docs available at http://localhost:8001/docs
```

**Setup Frontend:**
```bash
cd Trading_Simulator/frontend
npm install
npm run dev
# Frontend runs on http://localhost:5173
```

**Usage:**
- **Automated Mode:** Model sends API calls to `/orders/{id}/buy|sell`
- **Manual Mode:** User logs in via UI and creates orders through dashboard
- Both modes tracked in same database with unified analytics

---

## 🔌 Integration Points (Updated for New Pipeline)

### financial_data_aggregator → model_regime_comparison (Data Loading)
- **Connection:** SQL query to aggregator SQLite database
- **Data Used:** 
  - Fact tables: OHLCV data for stocks, crypto, bonds, commodities
  - Economic indicators (GDP, inflation, employment)
  - Dimension tables: company info, exchange details
- **Frequency:** Per pipeline execution (daily/weekly depending on schedule)
- **File:** `src/data/data_loader.py` in model_regime_comparison
- **Flow:** DataLoader → MarkovChainRegimeDetector → MonteCarloSimulator

### model_regime_comparison ↔ Ollama LLM (Asset Filtering)
- **Connection:** HTTP POST to local Ollama API (default: http://localhost:11434)
- **Data Sent:** 
  - Monte Carlo metrics (mean, VaR, ES, prob_loss)
  - Current regime info (type, confidence, persistence)
  - Risk profile constraints
- **Data Returned:** JSON with asset scores (0-1 per ticker)
- **Frequency:** Per pipeline run
- **File:** `src/advisory/llm_asset_selector.py`
- **Model:** llama2 (or configurable via env variable)

### model_regime_comparison → Trading_Simulator (Portfolio Execution)
- **Connection:** REST API calls (FastAPI on http://localhost:8001)
- **Endpoint:** POST `/portfolios` with PortfolioAllocation
- **Data Sent:**
  - positions: list of {ticker, quantity, entry_price}
  - asset_allocation breakdown
  - expected metrics (mean return, VaR, ES)
  - risk_profile_type used
  - regime_at_construction (audit trail)
- **Data Returned:** portfolio_id for tracking, created_at timestamp
- **Frequency:** Per pipeline execution
- **File:** `src/integrations/trading_simulator_client.py`

### Trading_Simulator Components (Internal)
- **Frontend ↔ Backend:** REST API (Axios)
  - GETs portfolio data, holdings, transactions
  - POSTs for manual order creation
- **Backend → Aggregator:** SQL queries for price lookups
- **Backend → Backend:** Internal service calls for portfolio management

---

## 📈 Example Workflow (NEW PIPELINE)

1. **Data Collection (Aggregator)** - CONTINUOUS
   - Cron job runs `unified_pipeline.py` daily
   - Updates price facts, economic indicators, company data
   - Stores in SQLite star schema (100,000+ records)

2. **Regime Analysis (Pipeline Phase 1-2)** - SCHEDULED
   - Pipeline loads latest prices from aggregator
   - MarkovChainRegimeDetector fits on 5-year history
   - Detects current regime (e.g., Bull market, confidence 87%)
   - Monte Carlo simulates 10,000 paths per asset
   - Generates VaR, ES, regime suitability scores

3. **Intelligent Filtering (Pipeline Phase 3)** - SCHEDULED
   - LLM queries with MC results + regime info
   - Returns asset scores: AAPL=0.92, MSFT=0.89, etc.
   - Filters high-volatility assets for conservative profile

4. **Portfolio Construction (Pipeline Phase 4)** - SCHEDULED
   - AnalysisPipeline calls LLMPortfolioConstructor
   - Allocates budget per risk profile (e.g., 40% stocks, 35% bonds, 20% crypto)
   - Selects top N assets per tier using LLM scores
   - Validates portfolio against all constraints
   - Example: MODERATE profile → 10 stocks, 5 bonds, 3 crypto, $20k cash

5. **Portfolio Execution (Pipeline Phase 6)** - SCHEDULED
   - TradingSimulatorClient POSTs portfolio to backend
   - Trading Simulator creates portfolio, executes all positions
   - Receives portfolio_id (e.g., "portfolio_20260410_001")
   - Records all transactions in database

6. **Ongoing Tracking** - CONTINUOUS
   - Dashboard shows portfolio NAV, positions, P&L
   - Daily: Risk metrics updated (Sharpe, Sortino, VaR)
   - Weekly: Monitor regime changes
   - Monthly: Optionally rebalance if regime shifts or VaR drifts

---

## 🎓 Key Concepts (NEW PIPELINE)

### Robo-Advisory Dual-Process Engine
The platform operates on two distinct but connected execution loops:
1. **Initial Creation**: Transforms human answers (via an onboarding questionnaire) into a machine-readable Risk-Profile. This determines time horizons (short vs. long term) and splits capital logically between risky/growth assets and safe/income assets.
2. **Ongoing Management**: A continuous evaluation loop that dynamically shifts existing portfolio investments to superior assets when market conditions change or the LLM identifies better opportunities, ensuring the user is always in the optimal allocation for their assigned risk tier.

### Hidden Markov Model (Markov Chain)
Statistical model detecting market regimes:
- **States**: 5 hidden market conditions (Bear, Sideways, Bull, Volatility Spike, Recovery)
- **Transitions**: Learned probabilities of switching between states
- **Current State**: Detected with confidence score (0-1)
- **Purpose**: Filter historical returns by regime for accurate Monte Carlo simulation

### Monte Carlo Simulation
Stochastic forward simulation of asset returns:
- **Paths**: 10,000+ simulated price trajectories per asset
- **Horizon**: 252 trading days (1 year forward)
- **Distribution**: Based on returns in detected regime (not full history)
- **Output**: Mean, median, VaR(95%), VaR(99%), ES(95%), ES(99%), confidence intervals

### Value at Risk (VaR) & Expected Shortfall (ES)
Risk metrics for portfolio management:
- **VaR(95%)**: Max acceptable loss in best 95% of scenarios (conservative threshold)
- **VaR(99%)**: Max acceptable loss in best 99% of scenarios (extreme risk threshold)
- **ES(95%)**: Average loss in worst 5% of outcomes (tail risk metric)
- **ES(99%)**: Average loss in worst 1% of outcomes (extreme tail risk)
- **Why both?** VaR can hide tail risk; ES captures it

### Risk Profiles (Predefined)
5 portfolio templates with specific constraints:
- **VERY_CONSERVATIVE**: 2% VaR(95%), 80% bonds, 10% stocks → Capital preservation
- **CONSERVATIVE**: 5% VaR(95%), 60% bonds, 20% stocks → Low drawdown
- **MODERATE**: 10% VaR(95%), 35% bonds, 40% stocks, 20% crypto → Balanced
- **AGGRESSIVE**: 15% VaR(95%), 60% stocks, 20% crypto, 15% bonds → Growth focused
- **VERY_AGGRESSIVE**: 25% VaR(95%), 70% stocks, 25% crypto → Maximum growth

### LLM-Driven Asset Selection
Using AI for intelligent filtering:
- **Input**: Monte Carlo results + regime + risk profile
- **Processing**: LLM evaluates semantic fit of each asset
- **Output**: Scores (0-1) indicating suitability for regime + profile
- **Advantage**: Captures nuanced constraints humans might miss

### Regime-Aware Portfolio Construction
Building allocations that adapt to market conditions:
- **Regime-Specific**: Uses assets suited to current market state
- **VaR-Constrained**: Enforces portfolio-level risk limits
- **Diversified**: Min 10 positions, max 5% per holding, max 20% per sector
- **Auction-Based**: Equal-weight positions within each asset tier

### Star Schema (Database Design)
Dimensional database for fast queries:
- **Fact Tables**: Events (prices, trades, indicators)
- **Dimension Tables**: Attributes (companies, dates, exchanges)
- **Advantage**: Enables flexible reporting and efficient joins

---

## 📊 Current Data State

| Asset Class | Count | Source | Status |
|------------|-------|--------|--------|
| **Stocks** | 250+ | Yahoo Finance | ✅ 100,000+ records |
| **Cryptocurrencies** | 50+ | CoinGecko | ✅ Populated |
| **Bonds** | 5 maturities | FRED + Yahoo | ✅ Populated |
| **Commodities** | 4+ types | Various | ✅ Populated |
| **Economic Indicators** | 15 series | FRED | ✅ Populated |

---

## 🔐 Configuration & Environment

**financial_data_aggregator:**
- API keys via `.env` (FRED, Alpha Vantage, CoinGecko)
- Configuration via `config/pipeline_config.yaml`
- Rate limiting built-in for API calls

**model_regime_comparison (NEW):**
- Database URL via `DATABASE_URL` env (aggregator SQLite)
- Ollama LLM via `OLLAMA_HOST` (default: http://localhost:11434)
- Ollama model via `OLLAMA_MODEL` (default: llama2)
- Risk profile config in `src/config/config.py`
- Markov model cache in `models/`

**Trading_Simulator:**
- Backend JWT authentication (admin via `create_admin.py`)
- Frontend login for manual portfolios
- API key authentication for model access
- Database: SQLite (trading_simulator.db)

---

## 📚 Documentation References

- **Aggregator Setup**: `financial_data_aggregator/README.md`
- **Model Framework**: `model_regime_comparison/README.md`
- **Simulator Guide**: `Trading_Simulator/PROJECT_SUMMARY.md`
- **Feature Engineering**: `model_regime_comparison/SCORING_SPECIFICATION.md`
- **Deployment**: `Trading_Simulator/DEPLOYMENT.md` & Docker configs

---

**Last Updated**: April 10, 2026  
**Maintained By**: Financial Data Pipeline Team
