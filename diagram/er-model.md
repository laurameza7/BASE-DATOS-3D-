# Entity-relationship model

```mermaid
erDiagram
    BUILDING ||--o{ PLACE : contains
    BUILDING ||--o{ PROGRAM : "hosts"
    PLACE ||--o{ PROGRAM : "faculty of"
    APP_USER ||--o{ CONVERSATION : "talks to Coopi"
    BUILDING {
        int id PK
        string code
        string name
        string description
        double pos_x
        double pos_z
        double width
        double depth
        int floors
        int basements
        string color
        string type
    }
    PLACE {
        int id PK
        string name
        string type
        int building_id FK
        int floor
        string description
        string schedule
        string phone
        string email
    }
    PROGRAM {
        int id PK
        string name
        string faculty
        string level
        string modality
        int duration_semesters
        string degree_title
        string description
        int building_id FK
        int place_id FK
    }
    FAQ {
        int id PK
        string category
        string question
        string answer
        string keywords
    }
    APP_USER {
        int id PK
        string name
        string email
        string password_hash
        string role
        timestamp created_at
        timestamp last_login
    }
    CONVERSATION {
        int id PK
        string question
        string answer
        string provider
        string action
        int user_id FK
        timestamp created_at
    }
```

* `APP_USER.password_hash` = BCrypt( SHA-256(password) ). The password itself is never stored.
* `CONVERSATION.user_id` is `NULL` for guests.
* The table is called `app_user` because `user` is a reserved word in PostgreSQL.
