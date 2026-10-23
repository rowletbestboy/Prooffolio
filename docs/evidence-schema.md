# Evidence schema

This diagram describes the private Evidence tables added by
`20261025100000_create_evidence.sql`. Existing target tables are created by
earlier migrations. `evidence_links.target_type` and `target_id` form a
polymorphic reference; the database trigger checks that the referenced target
exists and belongs to the same user. They are not direct foreign keys because
the target can be one of four different tables.

```mermaid
erDiagram
    AUTH_USERS ||--o{ EVIDENCE_RECORDS : owns
    AUTH_USERS ||--o{ EVIDENCE_LINKS : owns
    EVIDENCE_RECORDS ||--o{ EVIDENCE_LINKS : has
    PROJECTS ||--o{ EVIDENCE_LINKS : target
    SKILLS ||--o{ EVIDENCE_LINKS : target
    EXPERIENCE_RECORDS ||--o{ EVIDENCE_LINKS : target
    PORTFOLIO_RECORDS ||--o{ EVIDENCE_LINKS : target
    EVIDENCE_RECORDS ||--o| STORAGE_OBJECTS : file_path

    EVIDENCE_RECORDS {
        uuid id PK
        uuid user_id FK
        text kind
        text title
        text description
        text source_url
        text file_name
        text content_type
        bigint size_bytes
        text storage_path UK
        timestamptz created_at
        timestamptz updated_at
    }

    EVIDENCE_LINKS {
        uuid user_id PK, FK
        uuid evidence_id PK, FK
        text target_type PK
        uuid target_id PK
        timestamptz created_at
    }

    PROJECTS {
        uuid id PK
        uuid user_id FK
        text title
    }

    SKILLS {
        uuid id PK
        uuid user_id FK
        text name
    }

    EXPERIENCE_RECORDS {
        uuid id PK
        uuid user_id FK
        text title
    }

    PORTFOLIO_RECORDS {
        uuid id PK
        uuid user_id FK
        text title
        text record_type
    }

    STORAGE_OBJECTS {
        text bucket_id
        text name
    }
```

Storage objects live in the private `evidence` bucket at
`<user-id>/<generated-name>`. The app opens them using short-lived signed URLs.
An evidence file row cannot be deleted while its object remains in Storage;
the Storage API must remove the object first. URL evidence has no Storage
object. Deleting a linked project, skill, experience, certification, or
achievement removes that target's link rows while preserving the evidence.
