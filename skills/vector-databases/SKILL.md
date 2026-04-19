---
name: vector-databases
description: Vector similarity search and embedding databases for RAG, semantic search, and AI application backends. Use when the user needs to store and query embeddings, build a retriever, compare vector DB options, or size an index. Routes to leaf skills (chroma, faiss, pinecone, qdrant) and defines the decision rules between local vs. managed and dense vs. hybrid.
version: 1.0.0
author: hermes-CCC (ported from Hermes Agent by NousResearch)
license: MIT
metadata:
  hermes:
    tags: [vector-database, rag, retrieval, semantic-search, embeddings, chroma, faiss, pinecone, qdrant, hybrid-search]
---

# Vector Databases - Embeddings Storage and Similarity Search

## Purpose

Choose and operate the right vector store for the task: local ephemeral, local persistent, self-hosted scalable, or fully managed. Handle the end-to-end loop: embed, upsert, index, query, rerank, evaluate. Define when hybrid (dense + sparse) search is required and when plain dense is enough.

## Activation criteria

Activate when the user:

- Says "RAG", "retrieval", "semantic search", "vector database", "embeddings store", "similarity search".
- Asks to compare Chroma vs. Pinecone vs. Qdrant vs. FAISS vs. Weaviate vs. Milvus.
- Needs to size an index (N vectors, D dimensions, memory, p95 query latency).
- Needs hybrid search (BM25 + dense), metadata filtering, namespace isolation, or multi-tenant partitioning.
- Needs a "best chunk" strategy, reranker choice, or retrieval evaluation (Recall@k, MRR, nDCG).

Do not activate for training embedders (use `training`), for serving the LLM on top (use `inference`), or for generating the embeddings model (use `models`).

## Leaf skills and when to pick each

- `chroma` - open-source, embedded, developer-friendly. Default for notebooks, prototypes, and small apps (< 1M vectors).
- `faiss` - in-process C++ library, ultra-fast ANN, no server. Default for local research, batch retrieval, and when latency per query matters more than durability.
- `pinecone` - fully managed, serverless or pod-based, hybrid dense+sparse, namespaces. Default when the user wants zero-ops, multi-tenant, and to ship a product.
- `qdrant` - self-hostable Rust engine with strong filtering, payloads, quantization, distributed mode. Default for production on-prem or private cloud at 10M+ vectors.

Adjacent options (not in this pack but may be referenced): Weaviate (built-in modules), Milvus (very large scale), pgvector (inside Postgres).

## Procedure

1. Gather inputs:
   - Vector count (now and 12 months out).
   - Embedding dimension (e.g., 1536 for `text-embedding-3-large`, 768 for `e5`).
   - Query-per-second target and p95 latency target.
   - Filter / metadata needs (tenant id, date, category).
   - Hosting constraint (local only, on-prem, managed, air-gapped).
2. Pick the store from this decision table:

   | Scale | Hosting | Filters | Choice |
   |-------|---------|---------|--------|
   | < 1M  | local   | simple  | `chroma` |
   | any   | in-proc | any     | `faiss` |
   | > 1M  | managed | any     | `pinecone` |
   | > 1M  | on-prem | complex | `qdrant` |

3. Pick the embedder:
   - General-purpose: `text-embedding-3-small` (1536 dim) or `e5-large-v2` (1024).
   - Long-context: `bge-large-en-v1.5` or `jina-embeddings-v3`.
   - Multilingual: `multilingual-e5-large`.
4. Define the chunking strategy: size, overlap, and metadata to carry (doc id, section, page, URL).
5. Build the pipeline: ingest -> chunk -> embed -> upsert -> index -> query -> (optional rerank) -> answer.
6. Measure retrieval quality before measuring LLM answer quality. Use a held-out Q/A set and report Recall@k.

## Decision rules

- Always normalize to cosine similarity unless benchmarking says otherwise; pick a metric once and stick to it.
- Chunk size: start at 512 tokens with 64-token overlap; tune by measuring Recall@k on eval set.
- If users ask filtered queries (tenant, date, ACL), prefer Qdrant or Pinecone over raw FAISS.
- Add a reranker (Cohere rerank, BGE reranker) when top-1 accuracy matters; expect 5-15 point Recall@k gain for ~10x extra latency on top-k candidates.
- For 10M+ vectors use int8 or PQ quantization; measure recall delta before deploying.
- Hybrid (BM25 + dense) beats pure dense for exact-match queries (names, codes, IDs). Use Pinecone sparse+dense or Qdrant sparse vectors.

## Outputs

- Chosen store + one-line justification tied to scale/hosting/filters.
- Chunking + embedding plan with exact model and dimension.
- Index build command (or SDK snippet) and a query example.
- Evaluation plan: eval set size, Recall@k target, reranker on/off.
- Cost estimate (monthly) for managed options, or RAM/disk estimate for self-hosted.

## Failure modes

- Using a different embedder at query time vs. index time: all recall collapses; enforce a single embedder in code.
- Forgetting metadata at ingest: queries cannot filter; re-ingest is expensive.
- No eval harness: "retrieval is good" becomes vibes; always measure Recall@k on a held set.
- Cosine similarity with unnormalized vectors: subtle bugs; always L2-normalize or use inner-product metric configured to match.
- Over-chunking (50-token chunks): tiny context, poor recall. Under-chunking (2K-token chunks): dilution. Target 256-768.

## Commands

Chroma (local, persistent):

```python
import chromadb
client = chromadb.PersistentClient(path="./chroma_db")
col = client.get_or_create_collection("docs", metadata={"hnsw:space": "cosine"})
col.add(ids=["d1","d2"], documents=["alpha","beta"], metadatas=[{"src":"a"},{"src":"b"}])
print(col.query(query_texts=["alpha-ish"], n_results=2))
```

FAISS (in-process):

```python
import faiss, numpy as np
d = 768
index = faiss.IndexFlatIP(d)   # inner product, vectors must be L2-normalized
index.add(embs)                # embs: (N, d) float32, L2-normalized
D, I = index.search(query.reshape(1, d), k=5)
```

Pinecone (managed):

```python
from pinecone import Pinecone, ServerlessSpec
pc = Pinecone(api_key="...")
pc.create_index(name="docs", dimension=1536, metric="cosine",
                spec=ServerlessSpec(cloud="aws", region="us-east-1"))
idx = pc.Index("docs")
idx.upsert([("d1", [0.1]*1536, {"src":"a"}), ("d2", [0.2]*1536, {"src":"b"})])
idx.query(vector=[0.1]*1536, top_k=3, include_metadata=True)
```

Qdrant (self-hosted):

```bash
docker run -p 6333:6333 -v $(pwd)/qdrant_storage:/qdrant/storage qdrant/qdrant
```

```python
from qdrant_client import QdrantClient
from qdrant_client.models import Distance, VectorParams, PointStruct
c = QdrantClient(url="http://localhost:6333")
c.recreate_collection("docs", vectors_config=VectorParams(size=768, distance=Distance.COSINE))
c.upsert("docs", points=[PointStruct(id=1, vector=[0.1]*768, payload={"src":"a"})])
c.search("docs", query_vector=[0.1]*768, limit=5)
```

Simple evaluation harness:

```python
def recall_at_k(queries, gold, retrieve, k=10):
    hits = 0
    for q, g in zip(queries, gold):
        res = retrieve(q, k=k)
        if any(r == g for r in res):
            hits += 1
    return hits / len(queries)
```

## Hand-off contract

When routing, include:

- Vector count (current, projected) and dimension
- QPS and latency target
- Filter / metadata schema
- Embedder id and revision
- Hosting constraint
- Target recall + eval set location
