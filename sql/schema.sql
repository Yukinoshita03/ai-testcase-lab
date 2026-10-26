-- 核心版结构，参考 ai-testcase-studio/backend/app/models/。
-- 事务由 database.init_db() 管理，此文件只放建表和建索引语句。
-- 完整原项目结构见 reference/original-schema.sql；调整说明见 ../docs/database.md。

-- 1. 项目：所有需求、生成任务和正式用例的归属。
CREATE TABLE IF NOT EXISTS projects (
    id INTEGER PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    description TEXT NOT NULL DEFAULT '',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 2. 需求文档：保存需求原文和处理状态。
CREATE TABLE IF NOT EXISTS requirement_documents (
    id INTEGER PRIMARY KEY,
    project_id INTEGER NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    source_type VARCHAR(20) NOT NULL DEFAULT 'text',
    raw_content TEXT NOT NULL DEFAULT '',
    test_scope TEXT NOT NULL DEFAULT '',
    status VARCHAR(20) NOT NULL DEFAULT 'uploaded',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS ix_requirement_documents_project_id
    ON requirement_documents(project_id);

-- 3. 功能点：一份需求拆成多条可编辑、可确认的功能点。
CREATE TABLE IF NOT EXISTS requirement_items (
    id INTEGER PRIMARY KEY,
    document_id INTEGER NOT NULL REFERENCES requirement_documents(id) ON DELETE CASCADE,
    module VARCHAR(100) NOT NULL DEFAULT '',
    feature VARCHAR(200) NOT NULL,
    description TEXT NOT NULL DEFAULT '',
    acceptance_criteria TEXT NOT NULL DEFAULT '',
    constraints TEXT NOT NULL DEFAULT '',
    priority VARCHAR(10) NOT NULL DEFAULT 'P1',
    sort_order INTEGER NOT NULL DEFAULT 0,
    confirmed BOOLEAN NOT NULL DEFAULT 0 CHECK (confirmed IN (0, 1))
);
CREATE INDEX IF NOT EXISTS ix_requirement_items_document_id
    ON requirement_items(document_id);

-- 4. 生成任务：一次模型生成的策略、进度和错误信息。
CREATE TABLE IF NOT EXISTS generation_tasks (
    id INTEGER PRIMARY KEY,
    project_id INTEGER NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    document_id INTEGER NOT NULL REFERENCES requirement_documents(id) ON DELETE CASCADE,
    strategy VARCHAR(50) NOT NULL DEFAULT 'detailed',
    strategy_config TEXT NOT NULL DEFAULT '{}',
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    progress INTEGER NOT NULL DEFAULT 0,
    stage VARCHAR(100) NOT NULL DEFAULT '',
    error_message TEXT NOT NULL DEFAULT '',
    tokens_used INTEGER NOT NULL DEFAULT 0,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS ix_generation_tasks_project_id
    ON generation_tasks(project_id);
CREATE INDEX IF NOT EXISTS ix_generation_tasks_document_id
    ON generation_tasks(document_id);

-- 5. 用例草稿：模型输出，保存人工编辑和评审状态。
CREATE TABLE IF NOT EXISTS generated_case_drafts (
    id INTEGER PRIMARY KEY,
    task_id INTEGER NOT NULL REFERENCES generation_tasks(id) ON DELETE CASCADE,
    requirement_item_id INTEGER REFERENCES requirement_items(id) ON DELETE SET NULL,
    title VARCHAR(500) NOT NULL,
    priority VARCHAR(10) NOT NULL DEFAULT 'P2',
    case_type VARCHAR(20) NOT NULL DEFAULT 'functional',
    precondition TEXT NOT NULL DEFAULT '',
    steps TEXT NOT NULL DEFAULT '[]',
    expected_result TEXT NOT NULL DEFAULT '',
    review_status VARCHAR(20) NOT NULL DEFAULT 'pending',
    was_edited BOOLEAN NOT NULL DEFAULT 0 CHECK (was_edited IN (0, 1)),
    reject_reason VARCHAR(200) NOT NULL DEFAULT '',
    is_smoke BOOLEAN NOT NULL DEFAULT 0 CHECK (is_smoke IN (0, 1)),
    skill_name VARCHAR(50) NOT NULL DEFAULT ''
);
CREATE INDEX IF NOT EXISTS ix_generated_case_drafts_task_id
    ON generated_case_drafts(task_id);
CREATE INDEX IF NOT EXISTS ix_generated_case_drafts_requirement_item_id
    ON generated_case_drafts(requirement_item_id);

-- 6. 正式用例：采纳后的内容，用于用例库和 Excel 导出。
CREATE TABLE IF NOT EXISTS testcases (
    id INTEGER PRIMARY KEY,
    project_id INTEGER NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    draft_id INTEGER REFERENCES generated_case_drafts(id) ON DELETE SET NULL,
    requirement_item_id INTEGER REFERENCES requirement_items(id) ON DELETE SET NULL,
    title VARCHAR(500) NOT NULL,
    priority VARCHAR(10) NOT NULL DEFAULT 'P2',
    case_type VARCHAR(20) NOT NULL DEFAULT 'functional',
    is_smoke BOOLEAN NOT NULL DEFAULT 0 CHECK (is_smoke IN (0, 1)),
    precondition TEXT NOT NULL DEFAULT '',
    steps TEXT NOT NULL DEFAULT '[]',
    expected_result TEXT NOT NULL DEFAULT '',
    status VARCHAR(20) NOT NULL DEFAULT 'active',
    source VARCHAR(20) NOT NULL DEFAULT 'ai_generated',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS ix_testcases_project_id
    ON testcases(project_id);
CREATE INDEX IF NOT EXISTS ix_testcases_draft_id
    ON testcases(draft_id);
CREATE INDEX IF NOT EXISTS ix_testcases_requirement_item_id
    ON testcases(requirement_item_id);
