-- 原项目完整结构参考：来自 ai-testcase-studio/backend/app/models/*.py。
-- 由 SQLAlchemy 模型元数据编译为 SQLite DDL；仅包含结构，不含任何业务数据或密钥。
-- 此文件不由当前 init_db() 加载。
-- 注意：模型中的 Python default= 与 onupdate= 不会自动成为数据库默认值或触发器。
-- ORM relationship 的级联删除行为也不自动等同于数据库 ON DELETE CASCADE。

-- 表：users
CREATE TABLE IF NOT EXISTS users (
	id INTEGER NOT NULL,
	username VARCHAR(64) NOT NULL,
	password_hash VARCHAR(256) NOT NULL,
	is_admin BOOLEAN NOT NULL,
	is_active BOOLEAN NOT NULL,
	created_at DATETIME DEFAULT (CURRENT_TIMESTAMP) NOT NULL,
	PRIMARY KEY (id)
);
CREATE UNIQUE INDEX IF NOT EXISTS ix_users_username ON users (username);

-- 表：projects
CREATE TABLE IF NOT EXISTS projects (
	id INTEGER NOT NULL,
	user_id INTEGER NOT NULL,
	name VARCHAR(200) NOT NULL,
	description TEXT NOT NULL,
	is_eval BOOLEAN NOT NULL,
	created_at DATETIME DEFAULT (CURRENT_TIMESTAMP) NOT NULL,
	updated_at DATETIME DEFAULT (CURRENT_TIMESTAMP) NOT NULL,
	PRIMARY KEY (id),
	FOREIGN KEY(user_id) REFERENCES users (id)
);
CREATE INDEX IF NOT EXISTS ix_projects_user_id ON projects (user_id);
CREATE UNIQUE INDEX IF NOT EXISTS uq_projects_user_eval ON projects (user_id) WHERE is_eval = 1;

-- 表：system_config
CREATE TABLE IF NOT EXISTS system_config (
	id INTEGER NOT NULL,
	user_id INTEGER NOT NULL,
	llm_api_key VARCHAR(500) NOT NULL,
	llm_base_url VARCHAR(500) NOT NULL,
	llm_model VARCHAR(100) NOT NULL,
	llm_mock_mode BOOLEAN NOT NULL,
	eval_llm_api_key VARCHAR(500) NOT NULL,
	eval_llm_base_url VARCHAR(500) NOT NULL,
	eval_llm_model VARCHAR(100) NOT NULL,
	embedding_api_key VARCHAR(500) NOT NULL,
	embedding_base_url VARCHAR(500) NOT NULL,
	embedding_model VARCHAR(100) NOT NULL,
	PRIMARY KEY (id),
	FOREIGN KEY(user_id) REFERENCES users (id) ON DELETE CASCADE
);
CREATE UNIQUE INDEX IF NOT EXISTS ix_system_config_user_id ON system_config (user_id);

-- 表：eval_runs
CREATE TABLE IF NOT EXISTS eval_runs (
	id INTEGER NOT NULL,
	project_id INTEGER NOT NULL,
	label VARCHAR(100) NOT NULL,
	config TEXT NOT NULL,
	status VARCHAR(20) NOT NULL,
	progress INTEGER NOT NULL,
	stage VARCHAR(100) NOT NULL,
	error_message TEXT NOT NULL,
	metrics TEXT NOT NULL,
	created_at DATETIME DEFAULT (CURRENT_TIMESTAMP) NOT NULL,
	PRIMARY KEY (id),
	FOREIGN KEY(project_id) REFERENCES projects (id)
);

-- 表：eval_samples
CREATE TABLE IF NOT EXISTS eval_samples (
	id INTEGER NOT NULL,
	project_id INTEGER NOT NULL,
	title VARCHAR(200) NOT NULL,
	content TEXT NOT NULL,
	checkpoints TEXT NOT NULL,
	created_at DATETIME DEFAULT (CURRENT_TIMESTAMP) NOT NULL,
	PRIMARY KEY (id),
	FOREIGN KEY(project_id) REFERENCES projects (id)
);

-- 表：knowledge_documents
CREATE TABLE IF NOT EXISTS knowledge_documents (
	id INTEGER NOT NULL,
	project_id INTEGER NOT NULL,
	title VARCHAR(200) NOT NULL,
	source_type VARCHAR(20) NOT NULL,
	raw_content TEXT NOT NULL,
	status VARCHAR(20) NOT NULL,
	error_message TEXT NOT NULL,
	chunk_count INTEGER NOT NULL,
	created_at DATETIME DEFAULT (CURRENT_TIMESTAMP) NOT NULL,
	PRIMARY KEY (id),
	FOREIGN KEY(project_id) REFERENCES projects (id)
);

-- 表：requirement_documents
CREATE TABLE IF NOT EXISTS requirement_documents (
	id INTEGER NOT NULL,
	project_id INTEGER NOT NULL,
	title VARCHAR(200) NOT NULL,
	source_type VARCHAR(20) NOT NULL,
	raw_content TEXT NOT NULL,
	test_scope TEXT NOT NULL,
	status VARCHAR(20) NOT NULL,
	is_eval BOOLEAN NOT NULL,
	created_at DATETIME DEFAULT (CURRENT_TIMESTAMP) NOT NULL,
	PRIMARY KEY (id),
	FOREIGN KEY(project_id) REFERENCES projects (id)
);

-- 表：eval_results
CREATE TABLE IF NOT EXISTS eval_results (
	id INTEGER NOT NULL,
	run_id INTEGER NOT NULL,
	sample_id INTEGER NOT NULL,
	task_id INTEGER,
	status VARCHAR(20) NOT NULL,
	metrics TEXT NOT NULL,
	created_at DATETIME DEFAULT (CURRENT_TIMESTAMP) NOT NULL,
	PRIMARY KEY (id),
	FOREIGN KEY(run_id) REFERENCES eval_runs (id),
	FOREIGN KEY(sample_id) REFERENCES eval_samples (id)
);

-- 表：generation_tasks
CREATE TABLE IF NOT EXISTS generation_tasks (
	id INTEGER NOT NULL,
	project_id INTEGER NOT NULL,
	document_id INTEGER NOT NULL,
	strategy VARCHAR(50) NOT NULL,
	strategy_config TEXT NOT NULL,
	status VARCHAR(20) NOT NULL,
	progress INTEGER NOT NULL,
	stage VARCHAR(100) NOT NULL,
	error_message TEXT NOT NULL,
	tokens_used INTEGER NOT NULL,
	is_eval BOOLEAN NOT NULL,
	knowledge_refs TEXT NOT NULL,
	created_at DATETIME DEFAULT (CURRENT_TIMESTAMP) NOT NULL,
	updated_at DATETIME DEFAULT (CURRENT_TIMESTAMP) NOT NULL,
	PRIMARY KEY (id),
	FOREIGN KEY(project_id) REFERENCES projects (id),
	FOREIGN KEY(document_id) REFERENCES requirement_documents (id)
);

-- 表：knowledge_chunks
CREATE TABLE IF NOT EXISTS knowledge_chunks (
	id INTEGER NOT NULL,
	document_id INTEGER NOT NULL,
	content TEXT NOT NULL,
	heading VARCHAR(300) NOT NULL,
	chroma_id VARCHAR(64) NOT NULL,
	PRIMARY KEY (id),
	FOREIGN KEY(document_id) REFERENCES knowledge_documents (id)
);

-- 表：requirement_items
CREATE TABLE IF NOT EXISTS requirement_items (
	id INTEGER NOT NULL,
	document_id INTEGER NOT NULL,
	module VARCHAR(100) NOT NULL,
	feature VARCHAR(200) NOT NULL,
	description TEXT NOT NULL,
	acceptance_criteria TEXT NOT NULL,
	constraints TEXT NOT NULL,
	priority VARCHAR(10) NOT NULL,
	sort_order INTEGER NOT NULL,
	confirmed BOOLEAN NOT NULL,
	PRIMARY KEY (id),
	FOREIGN KEY(document_id) REFERENCES requirement_documents (id)
);

-- 表：generated_case_drafts
CREATE TABLE IF NOT EXISTS generated_case_drafts (
	id INTEGER NOT NULL,
	task_id INTEGER NOT NULL,
	requirement_item_id INTEGER,
	title VARCHAR(500) NOT NULL,
	priority VARCHAR(10) NOT NULL,
	case_type VARCHAR(20) NOT NULL,
	precondition TEXT NOT NULL,
	steps TEXT NOT NULL,
	expected_result TEXT NOT NULL,
	quality_status VARCHAR(20) NOT NULL,
	quality_issues TEXT NOT NULL,
	review_status VARCHAR(20) NOT NULL,
	was_edited BOOLEAN NOT NULL,
	reject_reason VARCHAR(200) NOT NULL,
	is_smoke BOOLEAN NOT NULL,
	skill_name VARCHAR(50) NOT NULL,
	judge_score FLOAT,
	judge_issues TEXT NOT NULL,
	PRIMARY KEY (id),
	FOREIGN KEY(task_id) REFERENCES generation_tasks (id),
	FOREIGN KEY(requirement_item_id) REFERENCES requirement_items (id)
);

-- 表：quality_reports
CREATE TABLE IF NOT EXISTS quality_reports (
	id INTEGER NOT NULL,
	task_id INTEGER NOT NULL,
	total_cases INTEGER NOT NULL,
	pass_count INTEGER NOT NULL,
	warning_count INTEGER NOT NULL,
	fail_count INTEGER NOT NULL,
	coverage_rate FLOAT NOT NULL,
	uncovered_features TEXT NOT NULL,
	suggestions TEXT NOT NULL,
	avg_judge_score FLOAT,
	hallucination_count INTEGER NOT NULL,
	duplicate_count INTEGER NOT NULL,
	created_at DATETIME DEFAULT (CURRENT_TIMESTAMP) NOT NULL,
	PRIMARY KEY (id),
	UNIQUE (task_id),
	FOREIGN KEY(task_id) REFERENCES generation_tasks (id)
);

-- 表：testcases
CREATE TABLE IF NOT EXISTS testcases (
	id INTEGER NOT NULL,
	project_id INTEGER NOT NULL,
	draft_id INTEGER,
	requirement_item_id INTEGER,
	title VARCHAR(500) NOT NULL,
	priority VARCHAR(10) NOT NULL,
	case_type VARCHAR(20) NOT NULL,
	is_smoke BOOLEAN NOT NULL,
	precondition TEXT NOT NULL,
	steps TEXT NOT NULL,
	expected_result TEXT NOT NULL,
	status VARCHAR(20) NOT NULL,
	source VARCHAR(20) NOT NULL,
	created_at DATETIME DEFAULT (CURRENT_TIMESTAMP) NOT NULL,
	updated_at DATETIME DEFAULT (CURRENT_TIMESTAMP) NOT NULL,
	PRIMARY KEY (id),
	FOREIGN KEY(project_id) REFERENCES projects (id),
	FOREIGN KEY(draft_id) REFERENCES generated_case_drafts (id),
	FOREIGN KEY(requirement_item_id) REFERENCES requirement_items (id)
);
