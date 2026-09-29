-- =====================================================================
-- 个人作品集数据库设计（MySQL 8.x）
-- 设计思路（最优解）：
--   公司 与 项目 是「多对多」关系（同一项目可能跨公司、同一公司多项目），
--   因此不把项目塞进公司表，而是拆三张核心表 + 一张关联表：
--
--   person            个人信息表        —— 页面头部数据来源
--   company           公司表            —— 公司维度主线（职位、工作内容）
--   project           项目表            —— 项目本体（名称、关键词、背景、成果、图片、链接、时间）
--   company_project   公司项目关联表    —— 多对多桥梁：项目归属 + 项目职责 + 优先级排序
--
--   前端两种维度渲染：
--   · 公司维度 = company JOIN company_project JOIN project，按 priority 排序
--   · 项目维度 = project JOIN company_project JOIN company，按 start_date 排序
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. 个人信息表（单人作品集，一条记录即可；多人可扩展）
-- ---------------------------------------------------------------------
CREATE TABLE person (
    id            BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name          VARCHAR(50)  NOT NULL COMMENT '姓名',
    avatar_url    VARCHAR(500) NULL     COMMENT '头像图片地址',
    job_title     VARCHAR(100) NOT NULL COMMENT '当前岗位',
    university    VARCHAR(100) NULL     COMMENT '毕业院校',
    major         VARCHAR(100) NULL     COMMENT '毕业专业',
    phone         VARCHAR(20)  NULL     COMMENT '手机号',
    email         VARCHAR(100) NULL     COMMENT '邮箱',
    self_intro    TEXT         NULL     COMMENT '自我介绍',
    created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) COMMENT '个人信息表';

-- ---------------------------------------------------------------------
-- 2. 公司表 —— 公司维度的主线（职位/工作内容属于"某人在某公司的任职"，
--    单人作品集直接放公司表即可；若多用户需拆出 company_member 任职表）
-- ---------------------------------------------------------------------
CREATE TABLE company (
    id            BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name          VARCHAR(200) NOT NULL COMMENT '公司名称',
    position      VARCHAR(100) NOT NULL COMMENT '职位（可多个，逗号分隔或拆任职表）',
    work_content  TEXT         NULL     COMMENT '岗位及工作内容',
    start_date    DATE         NULL     COMMENT '入职时间',
    end_date      DATE         NULL     COMMENT '离职时间（NULL=至今）',
    is_dispatch   TINYINT(1)   NOT NULL DEFAULT 0 COMMENT '是否派遣/外包 0否 1是',
    sort_order    INT          NOT NULL DEFAULT 0 COMMENT '展示顺序（倒序常显最新公司在前）',
    created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    KEY idx_sort (sort_order)
) COMMENT '公司表';

-- ---------------------------------------------------------------------
-- 3. 项目表 —— 项目本体，独立于公司存在
-- ---------------------------------------------------------------------
CREATE TABLE project (
    id            BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name          VARCHAR(200) NOT NULL COMMENT '项目名称',
    keywords      VARCHAR(500) NULL     COMMENT '项目关键词（逗号分隔；规范可拆 keyword 子表）',
    background    TEXT         NULL     COMMENT '项目背景',
    responsibility TEXT        NULL     COMMENT '项目职责描述（补充说明，角色主数据在关联表）',
    achievement   TEXT         NULL     COMMENT '项目成果',
    detail_url    VARCHAR(500) NULL     COMMENT '项目详细链接',
    start_date    DATE         NULL     COMMENT '项目开始时间（项目维度排序依据）',
    end_date      DATE         NULL     COMMENT '项目结束时间（NULL=进行中）',
    created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    KEY idx_start_date (start_date)
) COMMENT '项目表';

-- ---------------------------------------------------------------------
-- 4. 项目图片表（一个项目多张图，1:N，不放 project 主表保证规范）
-- ---------------------------------------------------------------------
CREATE TABLE project_image (
    id            BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    project_id    BIGINT UNSIGNED NOT NULL COMMENT '所属项目',
    image_url     VARCHAR(500) NOT NULL COMMENT '图片地址',
    caption       VARCHAR(200) NULL     COMMENT '图片说明',
    sort_order    INT    NOT NULL DEFAULT 0 COMMENT '展示顺序',
    KEY idx_project (project_id),
    CONSTRAINT fk_image_project FOREIGN KEY (project_id) REFERENCES project(id) ON DELETE CASCADE
) COMMENT '项目图片表';

-- ---------------------------------------------------------------------
-- 5. 公司项目关联表 —— 核心！解决"项目在哪家公司、担任什么角色、优先级"
--    · 收缩态展示所需字段全部可由此关联查询获得：
--      项目名称(project.name)、项目职责(role)、项目关键词(project.keywords)、项目时间(project.start_date)
-- ---------------------------------------------------------------------
CREATE TABLE company_project (
    id            BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    company_id    BIGINT UNSIGNED NOT NULL COMMENT '公司ID',
    project_id    BIGINT UNSIGNED NOT NULL COMMENT '项目ID',
    project_role  VARCHAR(50)  NOT NULL COMMENT '项目职责：项目负责人/核心成员/参与者…',
    priority      INT          NOT NULL DEFAULT 0 COMMENT '项目优先级（公司维度内排序依据，越小越靠前）',
    created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_company_project (company_id, project_id),
    KEY idx_priority (company_id, priority),
    CONSTRAINT fk_cp_company FOREIGN KEY (company_id) REFERENCES company(id) ON DELETE CASCADE,
    CONSTRAINT fk_cp_project FOREIGN KEY (project_id) REFERENCES project(id) ON DELETE CASCADE
) COMMENT '公司项目关联表（多对多）';

-- =====================================================================
-- 示例数据（来自用户提供的表格）
-- =====================================================================
INSERT INTO person (name, avatar_url, job_title, university, major, phone, email, self_intro) VALUES
('马思琪', NULL, 'AIGC产品经理 / AI项目经理', '待填写', '待填写', '138-XXXX-XXXX', 'your@email.com', '深耕 AI 应用产品与项目落地……');

INSERT INTO company (name, position, work_content, is_dispatch, sort_order) VALUES
('深圳市智慧建筑有限公司', '数据运维、AIGC产品经理', '负责AI产品线整体规划与落地：数据运维保障、AIGC产品设计、AI项目团队组建与交付管理。', 0, 2),
('招商信诺人寿保险有限公司', 'AI项目经理', '负责保险业务场景下AI项目的设计与交付管理，推动智能问答与知识库产品落地。', 1, 1);

INSERT INTO project (name, keywords, background, achievement, start_date) VALUES
('“小散工程”巡检AI',    '智能巡检,计算机视觉,安全生产', '针对小散工程现场巡检依赖人工的问题，构建AI巡检能力。', '实现隐患自动识别与告警。', '2024-01-01'),
('“小散工程”数据问答AI','RAG,Text2SQL,ChatBI',        '设计兼顾专业性与易用性的数据问答产品。',             '打通对话式取数链路。',     '2024-03-01'),
('“小散工程”答疑解惑AI','RAG,知识库,智能客服',        '面向工程规范与业务制度的智能答疑。',                 '上线智能答疑助手。',       '2024-05-01'),
('“深”深+业务问答AI',  'RAG,业务问答,大模型应用',     '面向建筑业务的综合问答AI。',                         '完成业务问答闭环。',       '2024-07-01'),
('i小讲+',              'AI培训,智能创作,保险业务',    '面向保险业务场景的智能讲习/创作产品。',               '完成产品设计与上线交付。', '2023-01-01'),
('知识库',              '知识管理,RAG,保险业务',       '构建保险业务统一知识库。',                           '完成知识库体系搭建。',     '2023-05-01');

INSERT INTO company_project (company_id, project_id, project_role, priority) VALUES
(1, 1, '项目负责人', 1),
(1, 2, '项目负责人', 2),
(1, 3, '核心成员',   3),
(1, 4, '项目负责人', 4),
(2, 5, '项目负责人', 1),
(2, 6, '项目负责人', 2);

-- =====================================================================
-- 两种维度的查询示例
-- =====================================================================

-- 公司维度：公司 → 职位/工作内容 → 项目（按优先级）
SELECT c.name AS 公司, c.position AS 职位, c.work_content AS 工作内容,
       p.name AS 项目, cp.project_role AS 项目职责, p.keywords AS 项目关键词,
       p.start_date AS 项目时间, cp.priority AS 优先级
FROM company c
JOIN company_project cp ON cp.company_id = c.id
JOIN project p          ON p.id = cp.project_id
ORDER BY c.sort_order DESC, cp.priority ASC;

-- 项目维度：项目 → 所属公司（按项目时间倒序）
SELECT p.name AS 项目, p.start_date AS 项目时间, cp.project_role AS 项目职责,
       p.keywords AS 项目关键词, c.name AS 所属公司
FROM project p
JOIN company_project cp ON cp.project_id = p.id
JOIN company c          ON c.id = cp.company_id
ORDER BY p.start_date DESC;
