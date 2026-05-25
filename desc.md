# CodeSwot jHound - Complete Implementation Guide

> **Fully automated job hunting system with ZERO monthly costs**
>
> AI-powered job discovery, application automation, and tracking system built with n8n, SeleniumBase, Ollama, and open-source tools.

**Author:** Mubarak Ibrahim (codeswot)  
**Last Updated:** May 15, 2026  
**Repository:** <https://github.com/codeswot/jHound>

---

## Table of Contents

1. [Overview](#overview)
2. [What It Does](#what-it-does)
3. [Tech Stack](#tech-stack)
4. [System Architecture](#system-architecture)
5. [Cost Analysis](#cost-analysis)
6. [Project Structure](#project-structure)
7. [Installation & Setup](#installation--setup)
8. [Complete Code & Scripts](#complete-code--scripts)
9. [n8n Workflow Designs](#n8n-workflow-designs)
10. [Database Schema](#database-schema)
11. [Configuration](#configuration)
12. [Schedule](#schedule)
13. [Monitoring & Metrics](#monitoring--metrics)
14. [Troubleshooting](#troubleshooting)
15. [Implementation Timeline](#implementation-timeline)
16. [Future Enhancements](#future-enhancements)

---

## Overview

**CodeSwot jHound** is an intelligent job hunting automation system that:

- 🔍 **Discovers 20+ relevant jobs every Friday** from 9+ job boards — **Remote Only, no exceptions**
- 🤖 **Auto-applies to 10+ jobs in a single weekly batch** via Easy Apply or personalized emails
- 📊 **Tracks everything** in PostgreSQL with detailed analytics
- 💬 **Notifies via WhatsApp** using your own account (free)
- 🌟 **Finds open source opportunities** with bounties and grants
- 📧 **Finds emails intelligently** using Google search operators (Hunter.io only for verification)
- 🧠 **AI-powered filtering** using free cloud Ollama LLMs (Llama 3.1)

### Key Metrics

**Target Performance:**

- Jobs discovered/week: 20+ (every Friday)
- Successful applications/week: 10+
- Application success rate: 50%+
- Response rate: 5-10% (industry standard)
- Open source opportunities/week: 5+ (1/weekday)

**ROI:**

- Time saved: 60 hours/month
- Value: $3,000/month (at $50/hour)
- Cost: $0/month
- **ROI: INFINITE ∞**

---

## What It Does

### Workflow: Discover → Apply → Track → Notify → Follow Up

#### 1. **Job Discovery (Friday 8:00 AM WAT — weekly)**

- Scrapes 9 job boards simultaneously — **Remote roles ONLY, onsite/hybrid are hard-rejected**:
  - LinkedIn Jobs (with Easy Apply detection)
  - RemoteOK
  - WeWorkRemotely
  - AngelList/Wellfound
  - Cryptocurrency Jobs
  - HackerNews Who's Hiring
  - Bitcoiner Jobs (<https://bitcoinerjobs.com>)
  - Indeed
  - Custom boards
- AI scores and ranks jobs by priority tier (Ollama):
  - **Tier 1 (score 80-100):** Bitcoin / Nostr / Open Source related → apply first
  - **Tier 2 (score 50-79):** Any remote tech role matching skills → apply normally
  - **Rejected:** Onsite, hybrid, or score < 50
- Deduplicates against database
- **Output:** ~20 highly relevant remote jobs, prioritised by Bitcoin/Nostr/Open Source fit

#### 2. **Application (Friday 8:30 AM - 5:00 PM)**

**Path A: Easy Apply (60% of jobs)**

- Detects "Easy Apply" button
- SeleniumBase auto-fills forms
- Handles multi-step applications
- Attaches resume automatically
- Submits application

**Path B: Email Application (40% of jobs)**

- Searches Google for hiring manager email
- Verifies email with Hunter.io (if quota available) or use AI to verify emails
- AI drafts personalized email (Ollama)
- Sends email with resume attachment
- Tracks sent emails

**Result:** 10+ successful applications in the Friday batch

#### 3. **Open Source Discovery (Mon-Fri, 1/day)**

- Searches GitHub for:
  - Issues with bounties ($100+ minimum)
  - Protocol Labs ecosystem projects
  - Bitcoin/Nostr grant opportunities
  - Repositories with HIRING.md
- Scores relevance 0-100
- **Output:** 5+ opportunities weekly

#### 4. **Tracking (Real-time)**

- Stores every job in PostgreSQL
- Records application method
- Tracks success/failure
- Builds success map by method
- Monitors response rates

#### 5. **Notifications**

**Weekly Summary (Friday 8:00 PM WAT via WhatsApp):**

```
🎯 jHound Daily Update

✅ Applications Today: 12
   • Easy Apply: 7
   • Email Sent: 5

🏢 Companies Applied:
   • Coinbase
   • Protocol Labs
   • Lightning Labs
   • ...and 9 more

📊 This Week: 67 applications
📈 Response Rate: 8.2%

👉 Dashboard: https://jHound.codeswot.dev
```

**Weekly Digest (Sunday 6:00 PM via Email):**

- Application trends
- Success rate by method
- Best performing job boards
- Response rate analysis
- Open source opportunities found
- Action items for next week

---

## Tech Stack

### Core Infrastructure

| Component | Purpose | Cost |
|-----------|---------|------|
| **n8n** | Workflow orchestration engine | $0 (open source) |
| **Docker Compose** | Container orchestration | $0 (open source) |
| **VPS** | Hosting (already owned) | $0 ✅ |

### Automation & AI

| Component | Purpose | Cost |
|-----------|---------|------|
| **SeleniumBase** | Stealth browser automation (UC Mode + CDP Mode) | $0 (open source) |
| **Ollama** | Local LLM (Llama 3.1 8B, Mistral 7B) | $0 (self-hosted) |
| **Selenium Grid** | Headless browser infrastructure | $0 (open source) |

### Data Layer

| Component | Purpose | Cost |
|-----------|---------|------|
| **PostgreSQL 15** | Application tracking database | $0 (self-hosted) |
| **Redis 7** | Rate limiting, caching, job queues | $0 (self-hosted) |

### External Services

| Component | Purpose | Cost |
|-----------|---------|------|
| **Google Search** | Email finding (search operators) | $0 (free) |
| **Hunter.io** | Email verification only (5/day limit) | $0 (free tier) ✅ |
| **whatsapp-web.js** | WhatsApp notifications | $0 (uses your account) ✅ |
| **GitHub API** | Open source project discovery | $0 (free tier) |
| **Resend** | Email sending | $0 (free tier: 3k emails/month) |

### Languages & Tools

- **Python 3.11** - Scrapers, AI scripts, automation
- **JavaScript/Node.js** - n8n workflows, WhatsApp notifier
- **SQL** - Database queries, stored procedures
- **Bash** - Deployment scripts

---

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        n8n Workflow Engine                       │
│                   (Central Orchestration Hub)                    │
└─────────────────────────────────────────────────────────────────┘
         │
         ├─────────────────┬─────────────────┬─────────────────┐
         │                 │                 │                 │
         ▼                 ▼                 ▼                 ▼
┌─────────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐
│ Job Discovery   │ │ Application │ │  Tracking   │ │ Open Source │
│    Module       │ │   Module    │ │   Module    │ │  Discovery  │
└─────────────────┘ └─────────────┘ └─────────────┘ └─────────────┘
         │                 │                 │                 │
         ▼                 ▼                 ▼                 ▼
┌─────────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐
│  SeleniumBase   │ │   Google    │ │ PostgreSQL  │ │  GitHub API │
│   (Scraping)    │ │   Search    │ │  Database   │ │  (Projects) │
│                 │ │             │ │             │ │             │
│   Ollama AI     │ │  Hunter.io  │ │   Redis     │ │             │
│  (Filtering)    │ │  (Verify)   │ │  (Cache)    │ │             │
└─────────────────┘ └─────────────┘ └─────────────┘ └─────────────┘
         │                 │                 │                 │
         └─────────────────┴─────────────────┴─────────────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │   Notifications  │
                    │                  │
                    │  whatsapp-web.js │
                    │     (Free)       │
                    │                  │
                    │  Email (Resend)  │
                    └──────────────────┘
```

### Data Flow

```
[Schedule Trigger: 8 AM WAT]
  ↓
[Execute: LinkedIn Scraper] ──┐
[Execute: RemoteOK Scraper] ──┤
[Execute: WWR Scraper] ───────┤
[Execute: AngelList Scraper] ─┤
[Execute: Crypto Jobs] ───────┤
[Execute: Bitcoiner Jobs] ────┤
[Execute: Indeed Scraper] ────┤→ [Merge Jobs Array]
                              ↓       ↓
                        [Deduplicate (Redis)]
                                      ↓
                                [AI Filter (Ollama)]
                                      ↓
                                [Split in Batches: 5]
                                      ↓
                          ┌───────────┴───────────┐
                          ▼                       ▼
                    [Has Easy Apply?]        [No Easy Apply]
                          │                       │
                          ▼                       ▼
              [Auto-Apply (SeleniumBase)]  [Find Email (Google)]
                          │                       │
                          │                       ▼
                          │              [Verify (Hunter.io)]
                          │                       │
                          │                       ▼
                          │              [Draft Email (Ollama)]
                          │                       │
                          │                       ▼
                          │              [Send Email (Resend)]
                          │                       │
                          └───────────┬───────────┘
                                      ▼
                          [Store in PostgreSQL]
                                      │
                          ┌───────────┴───────────┐
                          ▼                       ▼
                  [Update Redis Cache]    [Queue WhatsApp Notification]
                                                  ▼
                                          [Send via whatsapp-web.js]
```

---

## Cost Analysis

### Monthly Operating Costs

```
Infrastructure:
  VPS (Already owned):             $0/month ✅
  Domain + SSL (Optional):         $0 (use IP or existing domain)
  
External APIs:
  Hunter.io (5/day, free tier):    $0/month ✅
  WhatsApp (whatsapp-web.js):      $0/month ✅
  Resend Email (3k emails):        $0 (free tier) ✅
  GitHub API (free tier):          $0/month ✅
  Google Search:                   $0/month ✅
  
Self-Hosted (Free):
  n8n:                             $0
  Ollama:                          $0
  SeleniumBase:                    $0
  PostgreSQL:                      $0
  Redis:                           $0
  Selenium Grid:                   $0

────────────────────────────────────────
TOTAL:                           $0/month 🎉
```

### ROI Calculation

**Time Saved:**

- Manual job searching: 10 hours/week
- Application writing: 5 hours/week
- **Total:** 15 hours/week = 60 hours/month

**Value:**

- 60 hours × $50/hour = $3,000/month

**Cost:**

- $0/month (self-hosted on existing VPS)

**ROI:**

- Value / Cost = $3,000 / $0 = **INFINITE ∞**

---

## Project Structure

```
jHound/
├── docker-compose.yml              # All services orchestration
├── .env.example                    # Environment variables template
├── .env                            # Your actual credentials (gitignored)
├── README.md                       # Quick start guide
├── COMPLETE_GUIDE.md              # This file
│
├── scripts/
│   ├── init.sql                   # PostgreSQL database schema
│   │
│   ├── scrapers/
│   │   ├── linkedin_scraper.py    # LinkedIn job scraper (UC Mode)
│   │   ├── generic_scraper.py     # RemoteOK, WeWorkRemotely, etc.
│   │   └── requirements.txt       # Python dependencies
│   │
│   ├── ai/
│   │   ├── job_filter.py          # Ollama-powered job filtering
│   │   ├── email_drafter.py       # AI email generation
│   │   └── requirements.txt       # Python dependencies
│   │
│   ├── automation/
│   │   ├── auto_apply.py          # Easy Apply bot (SeleniumBase)
│   │   └── requirements.txt       # Python dependencies
│   │
│   ├── email_finder.py            # Google search + Hunter.io verification
│   ├── opensource_finder.py       # GitHub project discovery
│   ├── whatsapp_notifier.js       # Free WhatsApp notifications
│   └── package.json               # Node.js dependencies
│
├── workflows/
│   ├── 01_job_discovery.json      # Main discovery workflow
│   ├── 02_application.json        # Auto-apply + email workflow
│   ├── 03_notifications.json      # Daily/weekly summaries
│   └── 04_opensource_discovery.json  # Open source opportunities
│
├── resources/
│   ├── cv.docx                            # CV/resume
│   ├── recommendation_flutter.pdf         # Flutter recommendation letter
│   └── recomendation_flutter_plus.pdf     # Flutter+ recommendation letter
│
└── data/
    ├── cover_letter.pdf           # Optional cover letter
    └── cookies/
        └── linkedin_cookies.json  # LinkedIn auth cookies
```

---

## Installation & Setup

### Prerequisites

- ✅ VPS with Docker installed (you already have this)
- ✅ 8GB RAM minimum (16GB recommended)
- ✅ 20GB disk space
- ✅ Ports available: 5678 (n8n), 11434 (Ollama), 4444 (Selenium)

### Step 1: Clone Repository

```bash
# Create project directory
mkdir -p ~/jHound
cd ~/jHound

# Create subdirectories
mkdir -p scripts/{scrapers,ai,automation,cookies} workflows data
```

### Step 2: Docker Compose Setup

Create `docker-compose.yml`:

```yaml
version: '3.8'

services:
  # n8n Workflow Engine
  n8n:
    image: n8nio/n8n:latest
    container_name: jHound-n8n
    restart: unless-stopped
    ports:
      - "5678:5678"
    environment:
      - N8N_BASIC_AUTH_ACTIVE=true
      - N8N_BASIC_AUTH_USER=mubarak
      - N8N_BASIC_AUTH_PASSWORD=${N8N_PASSWORD}
      - N8N_HOST=0.0.0.0
      - N8N_PORT=5678
      - N8N_PROTOCOL=http
      - NODE_ENV=production
      - WEBHOOK_URL=${WEBHOOK_URL}
      - GENERIC_TIMEZONE=Africa/Lagos
      - EXECUTIONS_DATA_PRUNE=true
      - EXECUTIONS_DATA_MAX_AGE=168 # 7 days
    volumes:
      - n8n_data:/home/node/.n8n
      - ./scripts:/home/node/scripts
      - ./workflows:/home/node/workflows
      - ./data:/home/node/data
      - ./resources:/home/node/resources
    depends_on:
      - postgres
      - redis
      - ollama
    networks:
      - jHound

  # Ollama for Local LLM
  ollama:
    image: ollama/ollama:latest
    container_name: jHound-ollama
    restart: unless-stopped
    ports:
      - "11434:11434"
    volumes:
      - ollama_models:/root/.ollama
    networks:
      - jHound
    # Uncomment if you have GPU
    # deploy:
    #   resources:
    #     reservations:
    #       devices:
    #         - driver: nvidia
    #           count: 1
    #           capabilities: [gpu]

  # Selenium Grid for Browser Automation
  selenium-chrome:
    image: selenium/standalone-chrome:latest
    container_name: jHound-selenium
    restart: unless-stopped
    ports:
      - "4444:4444"
      - "7900:7900" # VNC viewer port (optional)
    shm_size: 2gb
    environment:
      - SE_NODE_MAX_SESSIONS=5
      - SE_NODE_SESSION_TIMEOUT=300
      - SE_VNC_NO_PASSWORD=1
    networks:
      - jHound

  # PostgreSQL Database
  postgres:
    image: postgres:15-alpine
    container_name: jHound-postgres
    restart: unless-stopped
    ports:
      - "5432:5432"
    environment:
      - POSTGRES_DB=jHound
      - POSTGRES_USER=jHound
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./scripts/init.sql:/docker-entrypoint-initdb.d/init.sql
    networks:
      - jHound

  # Redis for Caching & Rate Limiting
  redis:
    image: redis:7-alpine
    container_name: jHound-redis
    restart: unless-stopped
    ports:
      - "6379:6379"
    command: redis-server --appendonly yes
    volumes:
      - redis_data:/data
    networks:
      - jHound

  # pgAdmin (Optional - for database management)
  pgadmin:
    image: dpage/pgadmin4:latest
    container_name: jHound-pgadmin
    restart: unless-stopped
    ports:
      - "5050:80"
    environment:
      - PGADMIN_DEFAULT_EMAIL=mubarak@codeswot.dev
      - PGADMIN_DEFAULT_PASSWORD=${PGADMIN_PASSWORD}
    volumes:
      - pgadmin_data:/var/lib/pgadmin
    networks:
      - jHound

volumes:
  n8n_data:
  ollama_models:
  postgres_data:
  redis_data:
  pgadmin_data:

networks:
  jHound:
    driver: bridge
```

### Step 3: Environment Variables

Create `.env` file:

```bash
# n8n Configuration
N8N_PASSWORD=your_secure_password_here
WEBHOOK_URL=http://your-vps-ip:5678

# PostgreSQL
POSTGRES_PASSWORD=your_postgres_password_here

# pgAdmin (optional)
PGADMIN_PASSWORD=your_pgadmin_password

# API Keys
HUNTER_API_KEY=your_hunter_io_api_key  # Optional - free tier
RESEND_API_KEY=your_resend_api_key

# User Configuration
USER_EMAIL=hi@codeswot.dev
USER_PHONE_WHATSAPP=234XXXXXXXXXX  # Your WhatsApp number (no +)
USER_LINKEDIN_COOKIES={}  # Add LinkedIn cookies JSON

# GitHub (optional - higher rate limits)
GITHUB_TOKEN=your_github_personal_access_token
```

### Step 4: Start Services

```bash
# Start all containers
docker-compose up -d

# Check status
docker-compose ps

# Should see all services running:
# - jHound-n8n
# - jHound-ollama
# - jHound-selenium
# - jHound-postgres
# - jHound-redis
# - jHound-pgadmin (optional)

# View logs
docker-compose logs -f n8n
```

### Step 5: Initialize Ollama

```bash
# Pull AI models
docker exec -it jHound-ollama ollama pull llama3.1:8b
docker exec -it jHound-ollama ollama pull mistral:7b

# Verify models installed
docker exec -it jHound-ollama ollama list

# Test Ollama
curl http://localhost:11434/api/tags
```

### Step 6: Setup Database

```bash
# Database should auto-initialize from init.sql
# Verify tables created
docker exec -it jHound-postgres psql -U jHound -d jHound -c "\dt"

# Should see tables:
# - job_applications
# - job_skills
# - follow_ups
# - email_responses
# - execution_logs
```

### Step 7: Install Python Dependencies

```bash
# Enter n8n container
docker exec -it jHound-n8n bash

# Install Python packages
pip install --break-system-packages \
  seleniumbase \
  requests \
  redis \
  psycopg2-binary

# Exit container
exit
```

### Step 8: Install Node.js Dependencies

```bash
# Install WhatsApp dependencies
docker exec -it jHound-n8n npm install whatsapp-web.js qrcode-terminal

# Verify installation
docker exec -it jHound-n8n node -e "console.log(require('whatsapp-web.js'))"
```

### Step 9: Setup WhatsApp (One-time)

```bash
# Initialize WhatsApp (will show QR code)
docker exec -it jHound-n8n node /home/node/scripts/whatsapp_notifier.js init

# Scan QR code with your phone:
# 1. Open WhatsApp on your phone
# 2. Go to Settings > Linked Devices
# 3. Tap "Link a Device"
# 4. Scan the QR code shown in terminal

# Session will be saved to ~/.wwebjs_auth
# You won't need to scan again!

# Test notification
docker exec -it jHound-n8n node /home/node/scripts/whatsapp_notifier.js send "jHound is online! 🎯"
```

### Step 10: Access n8n Web UI

```bash
# Open browser
http://your-vps-ip:5678

# Login with credentials from .env:
# Username: mubarak
# Password: (value of N8N_PASSWORD)
```

### Step 11: Import Workflows

1. In n8n web UI, click "Workflows" → "Import from File"
2. Import each workflow from `workflows/` directory:
   - `01_job_discovery.json`
   - `02_application.json`
   - `03_notifications.json`
   - `04_opensource_discovery.json`

### Step 12: Configure Credentials in n8n

**PostgreSQL:**

- Host: `postgres`
- Port: `5432`
- Database: `jHound`
- User: `jHound`
- Password: (from .env `POSTGRES_PASSWORD`)

**Ollama:**

- Base URL: `http://ollama:11434`

**Resend (Email):**

- API Key: (from .env `RESEND_API_KEY`)

**Hunter.io (Optional):**

- API Key: (from .env `HUNTER_API_KEY`)

### Step 13: Test Individual Components

```bash
# Test LinkedIn scraper
docker exec -it jHound-n8n python3 /home/node/scripts/scrapers/linkedin_scraper.py \
  --keywords "Bitcoin" "NestJS" \
  --max-jobs 5

# Test AI job filter
docker exec -it jHound-n8n python3 /home/node/scripts/ai/job_filter.py \
  --input test_jobs.json

# Test email finder
docker exec -it jHound-n8n python3 /home/node/scripts/email_finder.py \
  --first-name John \
  --last-name Doe \
  --company "Acme Corp" \
  --domain acme.com

# Test open source finder
docker exec -it jHound-n8n python3 /home/node/scripts/opensource_finder.py \
  --skills Bitcoin NestJS Flutter \
  --min-bounty 100

# Test WhatsApp
docker exec -it jHound-n8n node /home/node/scripts/whatsapp_notifier.js \
  daily-summary '{"total_today": 12, "easy_apply_count": 7, "email_count": 5, "companies": ["Coinbase", "Protocol Labs"], "week_total": 67, "response_rate": 8.2}'
```

### Step 14: Activate Workflows

In n8n UI:

1. Open each workflow
2. Click "Activate" toggle (top right)
3. Verify schedule triggers are enabled

### Step 15: Monitor First Run

```bash
# Watch n8n logs for first scheduled run
docker-compose logs -f n8n

# Check PostgreSQL for stored jobs
docker exec -it jHound-postgres psql -U jHound -d jHound -c "SELECT COUNT(*) FROM job_applications;"

# Check Redis cache
docker exec -it jHound-redis redis-cli KEYS "*"
```

---

## Complete Code & Scripts

### Database Schema (`scripts/init.sql`)

```sql
-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Job Applications Table
CREATE TABLE job_applications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  -- Job Details
  job_title TEXT NOT NULL,
  company TEXT NOT NULL,
  company_domain TEXT,
  job_url TEXT UNIQUE NOT NULL,
  job_description TEXT,
  source_board TEXT NOT NULL, -- 'LinkedIn', 'RemoteOK', etc.
  
  -- Application Details
  application_method TEXT NOT NULL, -- 'easy_apply', 'email', 'manual'
  status TEXT DEFAULT 'applied', -- applied, rejected, interview, offer, ghosted
  applied_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Contact Information
  hiring_manager_name TEXT,
  hiring_manager_email TEXT,
  hiring_manager_linkedin TEXT,
  
  -- AI-Generated Content
  ai_generated_email JSONB, -- {subject, body}
  ai_job_match_score FLOAT, -- 0-100
  ai_reasoning TEXT,
  
  -- Tracking
  last_follow_up_at TIMESTAMPTZ,
  follow_up_count INTEGER DEFAULT 0,
  response_received_at TIMESTAMPTZ,
  response_type TEXT, -- 'rejection', 'interview', 'offer', 'generic'
  
  -- Metadata
  metadata JSONB, -- Additional flexible data
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_status ON job_applications(status);
CREATE INDEX idx_applied_at ON job_applications(applied_at DESC);
CREATE INDEX idx_company ON job_applications(company);
CREATE INDEX idx_source ON job_applications(source_board);
CREATE INDEX idx_application_method ON job_applications(application_method);

-- Job Skills Mapping
CREATE TABLE job_skills (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  job_id UUID REFERENCES job_applications(id) ON DELETE CASCADE,
  skill TEXT NOT NULL,
  is_required BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_job_skills_job_id ON job_skills(job_id);
CREATE INDEX idx_skill ON job_skills(skill);

-- Follow-up History
CREATE TABLE follow_ups (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  job_id UUID REFERENCES job_applications(id) ON DELETE CASCADE,
  sent_at TIMESTAMPTZ DEFAULT NOW(),
  email_subject TEXT,
  email_body TEXT,
  response_received BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_follow_ups_job_id ON follow_ups(job_id);

-- Email Responses
CREATE TABLE email_responses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  job_id UUID REFERENCES job_applications(id) ON DELETE CASCADE,
  from_email TEXT NOT NULL,
  subject TEXT,
  body TEXT,
  ai_classification TEXT, -- 'rejection', 'interview', 'offer', 'generic'
  received_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_email_responses_job_id ON email_responses(job_id);

-- Execution Logs (for monitoring)
CREATE TABLE execution_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  workflow_name TEXT NOT NULL,
  execution_id TEXT,
  status TEXT, -- success, error, warning
  message TEXT,
  metadata JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_execution_logs_workflow ON execution_logs(workflow_name);
CREATE INDEX idx_execution_logs_created ON execution_logs(created_at DESC);

-- Update trigger for updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_job_applications_updated_at 
  BEFORE UPDATE ON job_applications 
  FOR EACH ROW 
  EXECUTE FUNCTION update_updated_at_column();

-- Deduplication function
CREATE OR REPLACE FUNCTION job_exists(p_job_url TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS(SELECT 1 FROM job_applications WHERE job_url = p_job_url);
END;
$$ LANGUAGE plpgsql;

-- Analytics views
CREATE OR REPLACE VIEW application_stats AS
SELECT 
  DATE(applied_at) as date,
  COUNT(*) as total_applications,
  COUNT(*) FILTER (WHERE application_method = 'easy_apply') as easy_apply_count,
  COUNT(*) FILTER (WHERE application_method = 'email') as email_count,
  COUNT(*) FILTER (WHERE application_method = 'manual') as manual_count,
  COUNT(*) FILTER (WHERE response_received_at IS NOT NULL) as responses_received,
  ROUND(100.0 * COUNT(*) FILTER (WHERE response_received_at IS NOT NULL) / COUNT(*), 2) as response_rate
FROM job_applications
GROUP BY DATE(applied_at)
ORDER BY date DESC;

CREATE OR REPLACE VIEW source_performance AS
SELECT 
  source_board,
  COUNT(*) as total_jobs,
  AVG(ai_job_match_score) as avg_match_score,
  COUNT(*) FILTER (WHERE application_method = 'easy_apply') as easy_apply_available,
  COUNT(*) FILTER (WHERE response_received_at IS NOT NULL) as responses_received,
  ROUND(100.0 * COUNT(*) FILTER (WHERE response_received_at IS NOT NULL) / COUNT(*), 2) as response_rate
FROM job_applications
GROUP BY source_board
ORDER BY total_jobs DESC;
```

### LinkedIn Scraper (`scripts/scrapers/linkedin_scraper.py`)

```python
#!/usr/bin/env python3
"""
LinkedIn Jobs Scraper using SeleniumBase UC Mode
Bypasses bot detection, handles authentication via cookies
"""

from seleniumbase import SB
import json
import sys
from datetime import datetime
import time

def load_cookies(cookies_json_str):
    """Load LinkedIn cookies from JSON string"""
    try:
        return json.loads(cookies_json_str)
    except:
        return None

def scrape_linkedin_jobs(keywords, location="Remote", cookies_json=None, max_jobs=20):
    """
    Scrape LinkedIn jobs using SeleniumBase UC Mode
    
    Args:
        keywords: List of keywords to search
        location: Job location (default: Remote)
        cookies_json: LinkedIn cookies as JSON string
        max_jobs: Maximum number of jobs to scrape per keyword
    
    Returns:
        List of job dictionaries
    """
    all_jobs = []
    
    with SB(uc=True, test=True, headed=False) as sb:
        # Navigate to LinkedIn
        sb.activate_cdp_mode("https://www.linkedin.com")
        
        # Load cookies if provided
        if cookies_json:
            cookies = load_cookies(cookies_json)
            if cookies:
                for cookie in cookies:
                    sb.driver.add_cookie(cookie)
                sb.refresh()
                time.sleep(2)
        
        for keyword in keywords:
            # f_WT=2 is Remote filter
            search_url = f"https://www.linkedin.com/jobs/search/?keywords={keyword}&location={location}&f_WT=2"
            
            sb.open(search_url)
            time.sleep(3)
            
            # Scroll to load more jobs
            for _ in range(3):
                sb.execute_script("window.scrollTo(0, document.body.scrollHeight);")
                time.sleep(2)
            
            # Extract job cards
            try:
                job_cards = sb.find_elements('li.jobs-search-results__list-item')
                
                for i, card in enumerate(job_cards[:max_jobs]):
                    try:
                        # Click to load job details
                        card.click()
                        time.sleep(1)
                        
                        # Extract job information
                        title_elem = sb.find_element('h2.t-24')
                        company_elem = sb.find_element('a.app-aware-link')
                        location_elem = sb.find_element('span.tvm__text--low-emphasis')
                        description_elem = sb.find_element('div.jobs-description__content')
                        
                        # Get job URL
                        job_url = sb.get_current_url()
                        
                        # Check for Easy Apply button
                        has_easy_apply = sb.is_element_visible('button.jobs-apply-button')
                        
                        job_data = {
                            'job_title': title_elem.text.strip() if title_elem else '',
                            'company': company_elem.text.strip() if company_elem else '',
                            'location': location_elem.text.strip() if location_elem else location,
                            'job_description': description_elem.text.strip()[:1000] if description_elem else '',
                            'job_url': job_url,
                            'source_board': 'LinkedIn',
                            'has_easy_apply': has_easy_apply,
                            'search_keyword': keyword,
                            'scraped_at': datetime.now().isoformat()
                        }
                        
                        all_jobs.append(job_data)
                        
                    except Exception as e:
                        print(f"Error extracting job {i}: {str(e)}", file=sys.stderr)
                        continue
                        
            except Exception as e:
                print(f"Error finding job cards for keyword '{keyword}': {str(e)}", file=sys.stderr)
                continue
    
    return all_jobs

def main():
    """Main execution"""
    import argparse
    parser = argparse.ArgumentParser(description='Scrape LinkedIn jobs')
    parser.add_argument('--keywords', nargs='+', default=['Bitcoin', 'Nostr', 'NestJS', 'Flutter'], help='Job keywords')
    parser.add_argument('--location', default='Remote', help='Job location')
    parser.add_argument('--cookies', help='LinkedIn cookies as JSON string')
    parser.add_argument('--max-jobs', type=int, default=20, help='Max jobs per keyword')
    
    args = parser.parse_args()
    
    # Scrape jobs
    jobs = scrape_linkedin_jobs(
        keywords=args.keywords,
        location=args.location,
        cookies_json=args.cookies,
        max_jobs=args.max_jobs
    )
    
    # Output as JSON
    print(json.dumps(jobs, indent=2))

if __name__ == '__main__':
    main()
```

### Smart Email Finder (`scripts/email_finder.py`)

```python
#!/usr/bin/env python3
"""
Smart Email Finder using Google Search Operators
Falls back to Hunter.io only for verification (5/day limit)
"""

from seleniumbase import SB
import json
import sys
import re
import time
from datetime import datetime
import redis
import requests
import os

# Redis for rate limiting
redis_client = redis.Redis(host='redis', port=6379, decode_responses=True)

EMAIL_PATTERNS = [
    r'[\w\.-]+@[\w\.-]+\.\w+',
    r'[\w\.-]+\s*\[at\]\s*[\w\.-]+\s*\[dot\]\s*\w+',
    r'[\w\.-]+\s*@\s*[\w\.-]+\s*\.\s*\w+'
]

def build_google_search_queries(first_name, last_name, company, company_domain):
    """Build Google search queries to find email"""
    queries = [
        f'"{first_name} {last_name}" email "{company_domain}"',
        f'"{first_name} {last_name}" contact "{company}"',
        f'"{first_name}.{last_name}@{company_domain}"',
        f'"{first_name[0]}{last_name}@{company_domain}"',
        f'"{first_name} {last_name}" site:linkedin.com/in contact',
        f'site:{company_domain} team "{first_name} {last_name}"',
        f'"{first_name} {last_name}" "{company}" email',
    ]
    return [f"https://www.google.com/search?q={q}" for q in queries]

def extract_emails_from_text(text):
    """Extract all email addresses from text"""
    emails = set()
    
    for pattern in EMAIL_PATTERNS:
        matches = re.findall(pattern, text, re.IGNORECASE)
        for match in matches:
            email = match.replace(' [at] ', '@').replace('[at]', '@')
            email = email.replace(' [dot] ', '.').replace('[dot]', '.')
            email = email.replace(' @ ', '@').replace(' . ', '.')
            email = email.strip()
            
            if '@' in email and '.' in email:
                emails.add(email.lower())
    
    return list(emails)

def score_email_relevance(email, first_name, last_name, company_domain):
    """Score email relevance (0-100)"""
    score = 0
    email_lower = email.lower()
    first_lower = first_name.lower()
    last_lower = last_name.lower()
    
    if company_domain.lower() in email_lower:
        score += 40
    if first_lower in email_lower:
        score += 20
    if last_lower in email_lower:
        score += 20
    if f"{first_lower}.{last_lower}" in email_lower:
        score += 15
    if f"{first_lower[0]}{last_lower}" in email_lower:
        score += 10
    
    # Penalize generic emails
    generic_keywords = ['info', 'contact', 'support', 'hello', 'team']
    for keyword in generic_keywords:
        if keyword in email_lower.split('@')[0]:
            score -= 20
    
    return max(0, min(100, score))

def search_google_for_emails(first_name, last_name, company, company_domain, max_queries=3):
    """Search Google for email addresses"""
    queries = build_google_search_queries(first_name, last_name, company, company_domain)
    all_emails = set()
    
    with SB(uc=True, test=True, headed=False) as sb:
        for query_url in queries[:max_queries]:
            try:
                sb.open(query_url)
                time.sleep(2)
                page_text = sb.get_page_source()
                emails = extract_emails_from_text(page_text)
                all_emails.update(emails)
                time.sleep(3)  # Rate limiting
            except Exception as e:
                print(f"Error searching Google: {str(e)}", file=sys.stderr)
                continue
    
    # Score and sort
    scored_emails = []
    for email in all_emails:
        score = score_email_relevance(email, first_name, last_name, company_domain)
        if score > 30:
            scored_emails.append({
                'email': email,
                'score': score,
                'source': 'google_search'
            })
    
    scored_emails.sort(key=lambda x: x['score'], reverse=True)
    return scored_emails

def can_use_hunter_today():
    """Check if we have Hunter.io quota available"""
    today = datetime.now().strftime('%Y-%m-%d')
    key = f"hunter_usage:{today}"
    usage = redis_client.get(key)
    return usage is None or int(usage) < 5

def use_hunter_quota():
    """Increment Hunter.io usage counter"""
    today = datetime.now().strftime('%Y-%m-%d')
    key = f"hunter_usage:{today}"
    redis_client.incr(key)
    redis_client.expire(key, 86400)

def verify_email_with_hunter(email):
    """Use Hunter.io for email verification only"""
    hunter_api_key = os.getenv('HUNTER_API_KEY')
    if not hunter_api_key:
        return {'verified': False, 'source': 'no_hunter_key'}
    
    try:
        response = requests.get(
            'https://api.hunter.io/v2/email-verifier',
            params={'email': email, 'api_key': hunter_api_key}
        )
        
        if response.status_code == 200:
            data = response.json()
            return {
                'verified': data['data']['status'] in ['valid', 'accept_all'],
                'score': data['data'].get('score', 0),
                'source': 'hunter_verify'
            }
        return {'verified': False, 'source': 'hunter_error'}
    except Exception as e:
        print(f"Hunter.io error: {str(e)}", file=sys.stderr)
        return {'verified': False, 'source': 'hunter_exception'}

def find_email_smart(first_name, last_name, company, company_domain):
    """Smart email finder - Google first, Hunter.io for verification"""
    result = {
        'email': None,
        'confidence': 0,
        'method': None,
        'alternatives': [],
        'hunter_used': False
    }
    
    # Google search
    google_results = search_google_for_emails(first_name, last_name, company, company_domain)
    
    if google_results:
        top_result = google_results[0]
        
        # High confidence
        if top_result['score'] >= 70:
            result['email'] = top_result['email']
            result['confidence'] = top_result['score']
            result['method'] = 'google_high_confidence'
            result['alternatives'] = [r['email'] for r in google_results[1:3]]
            return result
        
        # Medium confidence - verify with Hunter
        if top_result['score'] >= 50 and can_use_hunter_today():
            verification = verify_email_with_hunter(top_result['email'])
            use_hunter_quota()
            result['hunter_used'] = True
            
            if verification['verified']:
                result['email'] = top_result['email']
                result['confidence'] = min(95, top_result['score'] + verification.get('score', 0) / 2)
                result['method'] = 'google_hunter_verified'
                result['alternatives'] = [r['email'] for r in google_results[1:3]]
                return result
        
        # Use best Google result
        result['email'] = top_result['email']
        result['confidence'] = top_result['score']
        result['method'] = 'google_unverified'
        result['alternatives'] = [r['email'] for r in google_results[1:3]]
        return result
    
    # Generate pattern guesses as fallback
    patterns = [
        f"{first_name.lower()}.{last_name.lower()}@{company_domain}",
        f"{first_name[0].lower()}{last_name.lower()}@{company_domain}",
        f"{first_name.lower()}{last_name.lower()}@{company_domain}"
    ]
    result['pattern_guesses'] = [{'email': p, 'confidence': 30} for p in patterns[:2]]
    
    return result

def main():
    import argparse
    parser = argparse.ArgumentParser(description='Find email address')
    parser.add_argument('--first-name', required=True)
    parser.add_argument('--last-name', required=True)
    parser.add_argument('--company', required=True)
    parser.add_argument('--domain', required=True)
    args = parser.parse_args()
    
    result = find_email_smart(args.first_name, args.last_name, args.company, args.domain)
    print(json.dumps(result, indent=2))

if __name__ == '__main__':
    main()
```

### WhatsApp Notifier (`scripts/whatsapp_notifier.js`)

```javascript
#!/usr/bin/env node
/**
 * Free WhatsApp Notifications using whatsapp-web.js
 * No Twilio required - uses your own WhatsApp account
 */

const { Client, LocalAuth } = require('whatsapp-web.js');
const qrcode = require('qrcode-terminal');
const fs = require('fs');

const CONFIG = {
    sessionPath: process.env.WHATSAPP_SESSION_PATH || '/home/node/.wwebjs_auth',
    targetNumber: process.env.USER_PHONE_WHATSAPP || '234XXXXXXXXXX',
    messageQueuePath: '/tmp/jHound_whatsapp_queue.json'
};

class WhatsAppNotifier {
    constructor() {
        this.client = new Client({
            authStrategy: new LocalAuth({ dataPath: CONFIG.sessionPath }),
            puppeteer: {
                headless: true,
                args: ['--no-sandbox', '--disable-setuid-sandbox']
            }
        });
        this.isReady = false;
        this.messageQueue = this.loadQueue();
        this.setupEventHandlers();
    }

    setupEventHandlers() {
        this.client.on('qr', (qr) => {
            console.log('Scan this QR code with WhatsApp:');
            qrcode.generate(qr, { small: true });
        });

        this.client.on('ready', () => {
            console.log('WhatsApp ready!');
            this.isReady = true;
            this.processQueue();
        });

        this.client.on('disconnected', (reason) => {
            console.log('Disconnected:', reason);
            this.isReady = false;
        });
    }

    async initialize() {
        await this.client.initialize();
        return new Promise((resolve) => {
            const check = setInterval(() => {
                if (this.isReady) {
                    clearInterval(check);
                    resolve();
                }
            }, 1000);
        });
    }

    loadQueue() {
        try {
            if (fs.existsSync(CONFIG.messageQueuePath)) {
                return JSON.parse(fs.readFileSync(CONFIG.messageQueuePath, 'utf8'));
            }
        } catch (err) {}
        return [];
    }

    saveQueue() {
        fs.writeFileSync(CONFIG.messageQueuePath, JSON.stringify(this.messageQueue, null, 2));
    }

    queueMessage(message) {
        this.messageQueue.push({
            message,
            timestamp: new Date().toISOString(),
            attempts: 0
        });
        this.saveQueue();
    }

    async processQueue() {
        while (this.messageQueue.length > 0) {
            const item = this.messageQueue.shift();
            try {
                await this.sendMessage(item.message);
            } catch (err) {
                if (item.attempts < 3) {
                    item.attempts++;
                    this.messageQueue.push(item);
                }
            }
            this.saveQueue();
            await new Promise(r => setTimeout(r, 2000));
        }
    }

    async sendMessage(message) {
        if (!this.isReady) {
            this.queueMessage(message);
            return { status: 'queued' };
        }

        const chatId = CONFIG.targetNumber.includes('@') 
            ? CONFIG.targetNumber 
            : `${CONFIG.targetNumber}@c.us`;

        await this.client.sendMessage(chatId, message);
        return { status: 'success' };
    }

    async destroy() {
        await this.client.destroy();
    }
}

class MessageFormatter {
    static dailySummary(stats) {
        return `🎯 *jHound Daily Update*

✅ *Applications Today:* ${stats.total_today}
   • Easy Apply: ${stats.easy_apply_count || 0}
   • Email Sent: ${stats.email_count || 0}

🏢 *Companies:*
${stats.companies.slice(0, 5).map(c => `   • ${c}`).join('\n')}

📊 *This Week:* ${stats.week_total || 0}
📈 *Response Rate:* ${stats.response_rate || 0}%

👉 Dashboard: https://jHound.codeswot.dev`;
    }

    static jobAlert(job) {
        return `🔔 *New Application*

*${job.job_title}*
${job.company}

Applied via: ${job.application_method}
Match: ${job.ai_job_match_score}/100

🔗 ${job.job_url}`;
    }
}

async function main() {
    const [,, command, ...args] = process.argv;
    const notifier = new WhatsAppNotifier();

    switch (command) {
        case 'init':
            await notifier.initialize();
            console.log('Session saved!');
            await notifier.destroy();
            break;

        case 'send':
            await notifier.initialize();
            await notifier.sendMessage(args[0]);
            await notifier.destroy();
            break;

        case 'daily-summary':
            const stats = JSON.parse(args[0] || '{}');
            await notifier.initialize();
            await notifier.sendMessage(MessageFormatter.dailySummary(stats));
            await notifier.destroy();
            break;

        default:
            console.log(`Usage:
  node whatsapp_notifier.js init
  node whatsapp_notifier.js send "message"
  node whatsapp_notifier.js daily-summary '{"stats"}'`);
            process.exit(1);
    }
    process.exit(0);
}

if (require.main === module) {
    main().catch(err => {
        console.error(err);
        process.exit(1);
    });
}
```

### Open Source Finder (`scripts/opensource_finder.py`)

```python
#!/usr/bin/env python3
"""
Open Source Project Discovery
Find paid opportunities matching user's skills
"""

import json
import sys
import requests
from datetime import datetime, timedelta
import os

GITHUB_API = "https://api.github.com"
GITHUB_TOKEN = os.getenv('GITHUB_TOKEN')  # Optional - higher rate limits

def search_github_paid_issues(keywords, min_bounty=100):
    """Search GitHub for issues with bounties"""
    paid_issues = []
    bounty_labels = ['bounty', 'paid', 'gitcoin', 'reward', '$']
    
    headers = {'Accept': 'application/vnd.github.v3+json'}
    if GITHUB_TOKEN:
        headers['Authorization'] = f'token {GITHUB_TOKEN}'
    
    for keyword in keywords:
        for label in bounty_labels[:3]:
            query = f'{keyword} label:{label} is:issue is:open'
            
            try:
                response = requests.get(
                    f'{GITHUB_API}/search/issues',
                    params={'q': query, 'sort': 'created', 'order': 'desc', 'per_page': 20},
                    headers=headers
                )
                
                if response.status_code == 200:
                    for issue in response.json().get('items', []):
                        bounty_amount = extract_bounty_amount(issue['title'], issue.get('body', ''))
                        
                        if bounty_amount and bounty_amount >= min_bounty:
                            paid_issues.append({
                                'title': issue['title'],
                                'repository': '/'.join(issue['repository_url'].split('/')[-2:]),
                                'url': issue['html_url'],
                                'bounty': bounty_amount,
                                'labels': [l['name'] for l in issue.get('labels', [])],
                                'created_at': issue['created_at'],
                                'keyword': keyword,
                                'source': 'github_issues'
                            })
            except Exception as e:
                print(f"Error searching: {str(e)}", file=sys.stderr)
                continue
    
    return paid_issues

def extract_bounty_amount(title, body):
    """Extract bounty amount from text"""
    import re
    text = f"{title} {body}".lower()
    patterns = [
        r'\$(\d+(?:,\d{3})*(?:\.\d{2})?)',
        r'(\d+(?:,\d{3})*)\s*(?:usd|dollars?)',
        r'bounty[:\s]+\$?(\d+(?:,\d{3})*)',
    ]
    
    amounts = []
    for pattern in patterns:
        matches = re.findall(pattern, text)
        for match in matches:
            try:
                amounts.append(int(match.replace(',', '')))
            except:
                continue
    
    return max(amounts) if amounts else 0

def search_bitcoin_nostr_projects(skills):
    """Search Bitcoin/Nostr ecosystem"""
    orgs = ['bitcoin', 'bitcoindevkit', 'lightningnetwork', 'nostr-protocol', 'fiatjaf']
    projects = []
    
    headers = {'Accept': 'application/vnd.github.v3+json'}
    if GITHUB_TOKEN:
        headers['Authorization'] = f'token {GITHUB_TOKEN}'
    
    for org in orgs:
        try:
            response = requests.get(
                f'{GITHUB_API}/orgs/{org}/repos',
                params={'per_page': 20, 'sort': 'stars'},
                headers=headers
            )
            
            if response.status_code == 200:
                for repo in response.json():
                    language = (repo.get('language') or '').lower()
                    description = (repo.get('description') or '').lower()
                    
                    matched_skills = [s for s in skills if s.lower() in language or s.lower() in description]
                    
                    if matched_skills or repo['stargazers_count'] > 500:
                        projects.append({
                            'name': repo['name'],
                            'repository': repo['full_name'],
                            'description': repo['description'],
                            'url': repo['html_url'],
                            'language': repo['language'],
                            'stars': repo['stargazers_count'],
                            'matched_skills': matched_skills,
                            'source': 'bitcoin_nostr',
                            'paid_likely': True,
                            'grant_info': 'Check bitcoingrants.org or OpenSats'
                        })
        except Exception as e:
            print(f"Error: {str(e)}", file=sys.stderr)
            continue
    
    return projects

def score_project_relevance(project, user_skills):
    """Score project 0-100"""
    score = 0
    score += len(project.get('matched_skills', [])) * 25
    
    if any(s.lower() in (project.get('language') or '').lower() for s in user_skills):
        score += 20
    
    stars = project.get('stars', 0)
    if stars > 1000:
        score += 15
    elif stars > 500:
        score += 10
    
    if project.get('bounty'):
        score += 20
    if project.get('paid_likely'):
        score += 10
    
    return min(100, score)

def main():
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument('--skills', nargs='+', default=['NestJS', 'TypeScript', 'Flutter', 'Bitcoin', 'Nostr'])
    parser.add_argument('--min-bounty', type=int, default=100)
    parser.add_argument('--min-score', type=int, default=50)
    args = parser.parse_args()
    
    all_opportunities = []
    
    print("Searching bounty issues...", file=sys.stderr)
    all_opportunities.extend(search_github_paid_issues(args.skills, args.min_bounty))
    
    print("Searching Bitcoin/Nostr...", file=sys.stderr)
    all_opportunities.extend(search_bitcoin_nostr_projects(args.skills))
    
    scored = []
    for opp in all_opportunities:
        score = score_project_relevance(opp, args.skills)
        if score >= args.min_score:
            opp['relevance_score'] = score
            scored.append(opp)
    
    scored.sort(key=lambda x: x['relevance_score'], reverse=True)
    print(json.dumps(scored, indent=2))

if __name__ == '__main__':
    main()
```

---

## n8n Workflow Designs

### Workflow 1: Job Discovery

**Trigger:** Schedule (Friday at 8:00 AM WAT — `0 8 * * 5`)

**Nodes:**

1. Schedule Trigger
2. Set Variables (keywords, location)
3. Execute Command: LinkedIn Scraper
4. Execute Command: Generic Scrapers
5. Merge Arrays
6. Code: Deduplicate (check Redis)
7. Execute Command: AI Filter (Ollama)
8. Split In Batches (5 jobs)
9. PostgreSQL: Check if exists
10. IF: Is new job?
11. Set: Prepare for application
12. Trigger Application Workflow (webhook)

### Workflow 2: Application

**Trigger:** Webhook (from Discovery workflow)

**Nodes:**

1. Webhook Trigger
2. IF: Has Easy Apply?
   - **Branch A:**
     - Execute: Auto-Apply Script
     - PostgreSQL: Insert (method='easy_apply')
   - **Branch B:**
     - Execute: Email Finder
     - IF: Email found?
       - Execute: AI Email Drafter
       - Send Email (Resend)
       - PostgreSQL: Insert (method='email')
     - ELSE:
       - PostgreSQL: Insert (method='manual', status='needs_email')
3. Merge
4. Redis: Update cache
5. Execute: WhatsApp notification (if >= 5 applications today)

### Workflow 3: Notifications

**Trigger:** Schedule (Friday at 8:00 PM WAT — `0 20 * * 5`)

**Nodes:**

1. Schedule Trigger
2. PostgreSQL: Query today's stats
3. Code: Format summary
4. Execute: WhatsApp daily summary
5. Code: Format HTML email
6. Send Email: Daily digest

---

## Configuration

### User Profile (for AI filtering)

```javascript
{
  "name": "Mubarak Ibrahim",
  "email": "hi@codeswot.dev",
  "phone": "+234XXXXXXXXXX",
  "skills": [
    "NestJS", "Flutter", "TypeScript", "JavaScript",
    "PostgreSQL", "Redis", "Docker", "Bitcoin", "Lightning Network",
    "Nostr", "React", "Next.js", "Python"
  ],
  "core_skills": ["NestJS", "Flutter", "Bitcoin", "Nostr", "TypeScript"],
  "location_preference": "Remote ONLY — hard filter, reject any onsite or hybrid listing",
  "timezone": "WAT (West Africa Time)",
  "job_priority": {
    "tier1_preferred": ["Bitcoin", "Nostr", "Lightning Network", "Open Source", "Decentralized"],
    "tier2_acceptable": "Any remote tech role matching skills",
    "rejected": ["onsite", "hybrid", "in-office", "on-site", "relocation required"]
  },
  "industries": [
    "Bitcoin/Cryptocurrency",
    "Nostr/Decentralized Social",
    "Open Source",
    "Privacy Tech",
    "Fintech",
    "Developer Tools",
    "Decentralized Systems"
  ],
  "resume_path": "/home/node/resources/cv.docx",
  "recommendations": [
    "/home/node/resources/recomendation_flutter_plus.pdf",
    "/home/node/resources/recommendation_flutter.pdf"
  ],
  "linkedin_url": "https://www.linkedin.com/in/codeswot",
  "github_url": "https://github.com/codeswot",
  "portfolio_url": "https://codeswot.me"
}
```

---

## Schedule

The system runs in a weekly rhythm to reduce noise and conserve Hunter.io credits:

### Friday 8:00 AM - Job Discovery (weekly)

- Scrapes 9 job boards (remote-only search params)
- Hard-rejects any onsite/hybrid listing immediately
- AI scores remaining jobs: Bitcoin/Nostr/Open Source → tier 1, any remote → tier 2
- Filters ~60 raw jobs → 20 ranked by priority
- Stores in PostgreSQL

### Friday 8:30 AM - 5:00 PM - Applications (weekly batch)

- Applies to 10+ jobs from the morning's discovery
- Mix of Easy Apply (60%) and Email (40%)
- Tier-1 WhatsApp company briefs sent instantly
- Tier-2 briefs batched (flushed in the 8 PM message)
- Tracks success/failure

### Friday 5:00 PM - Manual Review Digest

- Lists jobs stuck on `needs_email` / `needs_manual`
- Sent to WhatsApp (suppressed when queue is empty)

### Friday 8:00 PM - Weekly Summary

- WhatsApp summary of the day's applications
- Flushes the tier-2 batch

### Sunday 6:00 PM - Weekly Performance Email

- Source-board performance, response rate, tier breakdown

### Mon-Fri 9:00 AM - Open Source Discovery

- Pulls bounty issues + Bitcoin/Nostr/Lightning grant-friendly orgs
- ~1 opportunity per weekday (5+/week target)
- Stored in `opensource_opportunities`

### Daily 10:00 AM - Follow-up Sweep

- Reads `awaiting_followup` view
- Drives cadence from `FOLLOW_UP_AFTER_DAYS` (default 7) and `MAX_FOLLOW_UPS` (default 2)
- Most days this is a no-op since applications are weekly

### Hourly + 6-hourly - Response Handling

- Resend inbound webhook → Svix verify → AI classify → DB → WhatsApp alert
- 6-hourly backfill from Resend API as safety net

### Mon 7:00 AM - LinkedIn Cookie Health Check

- Validates current cookies still authenticate
- WhatsApp alert if expired

---

## Monitoring & Metrics

### Key Queries

```sql
-- Today's applications
SELECT COUNT(*) FROM job_applications 
WHERE DATE(applied_at) = CURRENT_DATE;

-- Success rate by method
SELECT 
  application_method,
  COUNT(*) as total,
  COUNT(*) FILTER (WHERE response_received_at IS NOT NULL) as responses,
  ROUND(100.0 * COUNT(*) FILTER (WHERE response_received_at IS NOT NULL) / COUNT(*), 2) as response_rate
FROM job_applications
GROUP BY application_method;

-- Best job boards
SELECT * FROM source_performance;

-- Weekly stats
SELECT * FROM application_stats
WHERE date >= CURRENT_DATE - INTERVAL '7 days';
```

---

## Troubleshooting

### LinkedIn Scraper Fails

```bash
# Update cookies
# 1. Login to LinkedIn
# 2. Export cookies (EditThisCookie extension)
# 3. Update .env LINKEDIN_COOKIES
docker-compose restart n8n
```

### WhatsApp Not Sending

```bash
# Re-authenticate
docker exec -it jHound-n8n node /home/node/scripts/whatsapp_notifier.js init
```

### Ollama Slow

```bash
# Use smaller model
docker exec -it jHound-ollama ollama pull mistral:7b
```

---

## Implementation Timeline

### Week 1: Foundation

- [ ] Docker Compose setup
- [ ] PostgreSQL schema
- [ ] Ollama models pulled
- [ ] WhatsApp authenticated
- [ ] Test scrapers

### Week 2: Core Automation

- [ ] LinkedIn scraper working
- [ ] AI filtering working
- [ ] Email finder working
- [ ] Auto-apply working
- [ ] Database storage working

### Week 3: Integration

- [ ] n8n workflows created
- [ ] Notifications working
- [ ] End-to-end test
- [ ] Error handling
- [ ] Monitoring setup

### Week 4: Launch

- [ ] Production deployment
- [ ] Monitor first week
- [ ] Tune AI thresholds
- [ ] Optimize success rate
- [ ] Document learnings

---

## Future Enhancements

- [ ] Interview scheduler integration
- [ ] Company research agent
- [ ] LinkedIn auto-networking
- [ ] Resume A/B testing
- [ ] Salary negotiation assistant
- [ ] Follow-up automation
- [ ] Job market analytics dashboard

---

## Success Criteria

**Week 4 Goals:**

- ✅ 20+ jobs discovered daily
- ✅ 10+ successful applications daily
- ✅ Application method success map built
- ✅ 5+ open source opportunities weekly
- ✅ Daily WhatsApp summaries
- ✅ Zero manual intervention

**Month 1 Goals:**

- ✅ 300+ total applications
- ✅ 50+ open source opportunities
- ✅ 5-10% response rate
- ✅ 2-5 interview invitations
- ✅ 95%+ uptime

---

## License

MIT License - Free to use, modify, and distribute

---

## Author

**Mubarak Ibrahim (codeswot)**

- Portfolio: <https://codeswot.me>
- GitHub: <https://github.com/codeswot>
- LinkedIn: <https://www.linkedin.com/in/codeswot>

---

**End of Complete Guide**

This document contains everything needed to build and deploy CodeSwot jHound from scratch with ZERO monthly costs.
