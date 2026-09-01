# Nexora — AI-Powered Data Intelligence Platform

> Upload your business data. Ask anything in plain language. Get instant AI-powered insights.

Nexora is a production-grade multi-tenant SaaS platform that enables non-technical teams to interact with their CSV data using natural language — powered by a custom RAG (Retrieval Augmented Generation) pipeline.

## Screenshots

<div align="center">
 <img src="docs/screenshots/login.png" alt="Nexora dashboard" width="280" />
  <img src="docs/screenshots/dashboard.png" alt="Nexora dashboard" width="280" />
  <img src="docs/screenshots/datasource.png" alt="Nexora upload flow" width="280" />
   <img src="docs/screenshots/chatscreen.png" alt="Nexora chat" width="280" />
</div>

---

## User Stories

**As a Marketing Manager:**
> "I uploaded last quarter's sales CSV and asked *'Which product had the highest revenue in February?'* — Nexora answered instantly with exact numbers. No SQL, no waiting for analysts."

**As an Operations Head:**
> "I asked *'Which city had the most delayed deliveries?'* — the AI analyzed my logistics data and gave me a ranked list in seconds."

**As a Team Owner:**
> "I invited my team members, assigned roles, and now everyone can query our shared data — securely, without exposing raw files."

---

## Why Nexora?

Persistent AI workspace for teams — large-file processing, vector search, multi-tenant collaboration, RBAC, persistent conversations, and API integration.

Built for data control and scalable AI workflows, rather than one-off conversational sessions.

---

## Tech Stack

## Tech Stack

**Backend:** Node.js, TypeScript, Express.js, PostgreSQL + pgvector, MongoDB, Redis, AWS S3, JWT, Zod

**AI / RAG:** Hugging Face Embeddings, `all-MiniLM-L6-v2`, pgvector, Groq LLM (`gpt-oss-20b`), Custom RAG Pipeline

**Mobile:** Flutter, Dart, Riverpod, Dio, SharedPreferences, Material 3

**Cloud & DevOps:** Docker, AWS ECR, ECS Fargate, AWS RDS, AWS ALB, Upstash Redis, GitHub Actions

---

## RAG Pipeline — How It Works

```
Step 1: CSV Upload
User uploads CSV → Stored in S3/MinIO
DB record created (datasource)

Step 2: Embedding (Indexing)
Each CSV row converted to text:
"product_name: iPhone 15, sales: 150, month: January"
        ↓
HuggingFace API → 384-dimensional vector
        ↓
Stored in PostgreSQL pgvector table

Step 3: Query (Retrieval)
User asks: "Best selling product?"
        ↓
Query → HuggingFace → query vector
        ↓
pgvector cosine similarity search
Top 5 most relevant rows retrieved

Step 4: Generation
Retrieved context + conversation history
        ↓
Groq LLM (openai/gpt-oss-20b)
        ↓
Natural language answer ✅

Step 5: Persistence
User message + AI answer saved to DB
Conversation history maintained
```

---

## Architecture

```
Flutter App (iOS/Android)
        ↓
AWS ALB (Load Balancer)
        ↓
AWS ECS Fargate (Node.js API)
    ↓           ↓           ↓           ↓
AWS RDS     MongoDB      Upstash     AWS S3
PostgreSQL   Atlas        Redis      (Files)
+ pgvector  (Chats)    (Sessions)
        ↓
HuggingFace API    Groq API
(Embeddings)       (LLM Chat)
```

---

## Multi-Tenancy & Security

```
Every organization's data is completely isolated:
→ org_id on every table
→ JWT contains orgId — injected by middleware
→ Every DB query filters by org_id
→ No cross-tenant data leakage

Role-Based Access Control:
OWNER  → Full access, invite members, delete org
ADMIN  → Manage members, upload data
MEMBER → View and query data only

JWT Security:
→ Access token: 15 minutes
→ Refresh token: 7 days
→ Logout: refresh token blacklisted in Redis
→ Token rotation on every refresh
```

---

## Local Setup

```bash
# Clone
git clone https://github.com/sumit2393/Nexora.git
cd Nexora

# Start Docker services
docker compose -f infra/docker-compose.yml up -d

# Install dependencies
cd apps/api && npm install

# Environment
cp .env.example .env
# Fill in your keys

# Run
npm run dev
```

**Services started by Docker:**
- PostgreSQL + pgvector → localhost:5432
- MongoDB → localhost:27017
- Redis → localhost:6379
- MinIO (S3) → localhost:9000

---

## Environment Variables

```env
NODE_ENV=development
PORT=3000
PostgreSQL= your secret keys
MONGO_URI=localhost
Redis=your key
JWT=your secret
AWS / MinIO= your keys
# AI
GROQ_API_KEY=your_groq_key
HUGGINGFACE_API_KEY=your_hf_key
```

---

## What Makes This Production-Grade

```
✅ Multi-tenant architecture — org-level data isolation
✅ JWT with Redis blacklisting — secure token management
✅ Custom RAG pipeline — not just API integration
✅ pgvector — no separate vector DB needed
✅ Dockerized — same environment everywhere
✅ AWS ECS Fargate — serverless, auto-scaling
✅ Role-based access control — enterprise ready
✅ Error handling — graceful failures
✅ Environment validation — Zod schema on startup
✅ Conversation persistence — full chat history
```

---

## License

MIT © 2026 Sumit Kumar

---

*Built to showcase production AI engineering skills — RAG pipeline, multi-tenant SaaS, cloud deployment, and mobile integration.*