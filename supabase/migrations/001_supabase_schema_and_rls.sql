-- =============================================================================
-- CASHEW STUDY DOCUMENT MANAGER - SUPABASE POSTGRESQL SCHEMA & RLS POLICIES
-- Tích hợp Hệ sinh thái Cloud: Firebase Auth (Google Sign-In) + Firebase Storage + Supabase
-- =============================================================================

-- 1. HÀM TRợ GIÚP TRÍCH XUẤT UID NGƯỜI DÙNG TỪ FIREBASE JWT HOẶC SUPABASE AUTH
CREATE OR REPLACE FUNCTION public.current_user_uid()
RETURNS TEXT
LANGUAGE sql
STABLE
AS $$
  SELECT COALESCE(
    nullif(current_setting('request.jwt.claim.sub', true), ''),
    (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'sub'),
    auth.uid()::text
  );
$$;

-- =============================================================================
-- 2. BẢNG NGƯỜI DÙNG (USERS TABLE)
-- Đồng bộ tự động sau khi người dùng đăng nhập Google qua Firebase Auth
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.users (
  uid TEXT PRIMARY KEY,                       -- Firebase Auth UID (Google Account UID)
  email TEXT UNIQUE NOT NULL,                 -- Địa chỉ Gmail đăng nhập
  display_name TEXT NOT NULL,                 -- Họ tên hiển thị
  photo_url TEXT DEFAULT '',                  -- Ảnh đại diện Google
  role_title TEXT DEFAULT 'Sinh viên',        -- Vai trò học thuật (Giảng viên / Trợ giảng / Sinh viên)
  department TEXT DEFAULT 'Khoa CNTT',        -- Khoa / Bộ môn
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  last_login_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);

-- =============================================================================
-- 3. BẢNG MÔN HỌC / HỌC PHẦN (SUBJECTS TABLE)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.subjects (
  id TEXT PRIMARY KEY,
  code TEXT NOT NULL,
  name TEXT NOT NULL,
  lecturer TEXT DEFAULT '',
  color_value BIGINT NOT NULL DEFAULT 4280193253,
  icon_name TEXT NOT NULL DEFAULT 'book',
  semester TEXT NOT NULL DEFAULT 'HK1 2026-2027',
  credit_count INTEGER NOT NULL DEFAULT 3,
  owner_uid TEXT REFERENCES public.users(uid) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================================
-- 4. BẢNG TÀI LIỆU HỌC TẬP (DOCUMENTS TABLE)
-- Kết nối trực tiếp với tệp vật lý lưu trên Firebase Storage qua storage_path & file_url
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.documents (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL CHECK (char_length(trim(title)) >= 3),
  description TEXT DEFAULT '',
  subject_id TEXT NOT NULL REFERENCES public.subjects(id) ON DELETE CASCADE,
  owner_uid TEXT NOT NULL REFERENCES public.users(uid) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('lecture', 'assignment', 'reference', 'exam')),
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'inProgress', 'completed', 'archived')),
  priority TEXT NOT NULL DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
  file_url TEXT DEFAULT '',                   -- Download URL từ Firebase Storage hoặc liên kết ngoài
  storage_path TEXT DEFAULT '',               -- Đường dẫn vật lý trên Firebase Storage: users/{owner_uid}/subjects/{subject_id}/documents/{doc_id}/{filename}
  file_name TEXT DEFAULT '',                  -- Tên file gốc khi tải lên
  file_type TEXT NOT NULL DEFAULT 'PDF',
  file_size_bytes BIGINT NOT NULL DEFAULT 0,
  due_date TIMESTAMPTZ,
  is_favorite BOOLEAN NOT NULL DEFAULT FALSE,
  tags TEXT[] DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_documents_owner_uid ON public.documents(owner_uid);
CREATE INDEX IF NOT EXISTS idx_documents_subject_id ON public.documents(subject_id);
CREATE INDEX IF NOT EXISTS idx_documents_tags ON public.documents USING GIN(tags);

-- =============================================================================
-- 5. BẢNG QUYỀN CHIA SẺ TRUY CẬP (PERMISSIONS TABLE)
-- Quản lý phân quyền truy cập tài liệu giữa các người dùng (viewer / editor)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.permissions (
  id TEXT PRIMARY KEY,
  document_id TEXT NOT NULL REFERENCES public.documents(id) ON DELETE CASCADE,
  shared_with_uid TEXT NOT NULL REFERENCES public.users(uid) ON DELETE CASCADE,
  shared_with_email TEXT NOT NULL,
  permission_level TEXT NOT NULL CHECK (permission_level IN ('viewer', 'editor')),
  granted_by_uid TEXT NOT NULL REFERENCES public.users(uid) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT uq_document_shared_user UNIQUE (document_id, shared_with_uid),
  CONSTRAINT chk_not_share_with_self CHECK (shared_with_uid <> granted_by_uid)
);

CREATE INDEX IF NOT EXISTS idx_permissions_document_id ON public.permissions(document_id);
CREATE INDEX IF NOT EXISTS idx_permissions_shared_with_uid ON public.permissions(shared_with_uid);

-- =============================================================================
-- 6. HÀM KIỂM TRA PHÂN QUYỀN TRUY CẬP TÀI LIỆU (SECURITY DEFINER)
-- =============================================================================
CREATE OR REPLACE FUNCTION public.can_view_document(target_doc_id TEXT, user_uid TEXT)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.documents d
    WHERE d.id = target_doc_id
      AND (
        d.owner_uid = user_uid
        OR EXISTS (
          SELECT 1 FROM public.permissions p
          WHERE p.document_id = d.id
            AND p.shared_with_uid = user_uid
            AND p.permission_level IN ('viewer', 'editor')
        )
      )
  );
$$;

CREATE OR REPLACE FUNCTION public.can_edit_document(target_doc_id TEXT, user_uid TEXT)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.documents d
    WHERE d.id = target_doc_id
      AND (
        d.owner_uid = user_uid
        OR EXISTS (
          SELECT 1 FROM public.permissions p
          WHERE p.document_id = d.id
            AND p.shared_with_uid = user_uid
            AND p.permission_level = 'editor'
        )
      )
  );
$$;

CREATE OR REPLACE FUNCTION public.is_document_owner(target_doc_id TEXT, user_uid TEXT)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.documents d
    WHERE d.id = target_doc_id AND d.owner_uid = user_uid
  );
$$;

-- =============================================================================
-- 7. THIẾT LẬP CHÍNH SÁCH BẢO MẬT ROW LEVEL SECURITY (RLS POLICIES)
-- =============================================================================

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subjects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.permissions ENABLE ROW LEVEL SECURITY;

-- 7.1. Chính sách RLS cho bảng USERS
-- Mọi người dùng đã đăng nhập có thể tìm kiếm thông tin cơ bản (email, tên) để chia sẻ tài liệu
CREATE POLICY "users_select_authenticated"
  ON public.users
  FOR SELECT
  USING (public.current_user_uid() IS NOT NULL);

-- Người dùng chỉ được phép tạo hoặc cập nhật hồ sơ của chính mình
CREATE POLICY "users_insert_self"
  ON public.users
  FOR INSERT
  WITH CHECK (uid = public.current_user_uid());

CREATE POLICY "users_update_self"
  ON public.users
  FOR UPDATE
  USING (uid = public.current_user_uid())
  WITH CHECK (uid = public.current_user_uid());

-- 7.2. Chính sách RLS cho bảng SUBJECTS
-- Mọi người dùng đã xác thực có thể xem danh mục môn học
CREATE POLICY "subjects_select_all"
  ON public.subjects
  FOR SELECT
  USING (public.current_user_uid() IS NOT NULL);

CREATE POLICY "subjects_insert_authenticated"
  ON public.subjects
  FOR INSERT
  WITH CHECK (public.current_user_uid() IS NOT NULL);

CREATE POLICY "subjects_update_owner"
  ON public.subjects
  FOR UPDATE
  USING (owner_uid IS NULL OR owner_uid = public.current_user_uid());

CREATE POLICY "subjects_delete_owner"
  ON public.subjects
  FOR DELETE
  USING (owner_uid IS NULL OR owner_uid = public.current_user_uid());

-- 7.3. Chính sách RLS cho bảng DOCUMENTS (Trọng tâm phân quyền)
-- SELECT: Chỉ Chủ sở hữu (owner_uid) HOẶC người được cấp quyền (viewer / editor) trong bảng permissions mới đọc được tài liệu
CREATE POLICY "documents_select_owner_or_shared"
  ON public.documents
  FOR SELECT
  USING (
    owner_uid = public.current_user_uid()
    OR EXISTS (
      SELECT 1 FROM public.permissions p
      WHERE p.document_id = public.documents.id
        AND p.shared_with_uid = public.current_user_uid()
    )
  );

-- INSERT: Người dùng chỉ được tạo tài liệu với owner_uid là chính mình
CREATE POLICY "documents_insert_owner_only"
  ON public.documents
  FOR INSERT
  WITH CHECK (
    owner_uid = public.current_user_uid()
  );

-- UPDATE: Chủ sở hữu (owner_uid) HOẶC người được chia sẻ với quyền 'editor' được phép cập nhật thông tin tài liệu
-- Đồng thời đảm bảo không ai được phép chiếm quyền sở hữu (owner_uid không bị thay đổi trái phép)
CREATE POLICY "documents_update_owner_or_editor"
  ON public.documents
  FOR UPDATE
  USING (
    owner_uid = public.current_user_uid()
    OR EXISTS (
      SELECT 1 FROM public.permissions p
      WHERE p.document_id = public.documents.id
        AND p.shared_with_uid = public.current_user_uid()
        AND p.permission_level = 'editor'
    )
  )
  WITH CHECK (
    owner_uid = public.current_user_uid()
    OR EXISTS (
      SELECT 1 FROM public.permissions p
      WHERE p.document_id = public.documents.id
        AND p.shared_with_uid = public.current_user_uid()
        AND p.permission_level = 'editor'
    )
  );

-- DELETE: CHỈ Chủ sở hữu (owner_uid) mới có quyền xóa tài liệu (Editor và Viewer đều bị chặn)
CREATE POLICY "documents_delete_owner_only"
  ON public.documents
  FOR DELETE
  USING (
    owner_uid = public.current_user_uid()
  );

-- 7.4. Chính sách RLS cho bảng PERMISSIONS (Quản lý quyền chia sẻ)
-- SELECT: Chủ sở hữu tài liệu hoặc người được nhận chia sẻ có thể xem bản ghi phân quyền
CREATE POLICY "permissions_select_owner_or_recipient"
  ON public.permissions
  FOR SELECT
  USING (
    shared_with_uid = public.current_user_uid()
    OR granted_by_uid = public.current_user_uid()
    OR public.is_document_owner(document_id, public.current_user_uid())
  );

-- INSERT: Chỉ Chủ sở hữu (owner_uid) của tài liệu mới được phép chia sẻ (thêm quyền mới)
CREATE POLICY "permissions_insert_document_owner_only"
  ON public.permissions
  FOR INSERT
  WITH CHECK (
    granted_by_uid = public.current_user_uid()
    AND public.is_document_owner(document_id, public.current_user_uid())
  );

-- UPDATE: Chỉ Chủ sở hữu của tài liệu mới được phép thay đổi cấp độ quyền (viewer <-> editor)
CREATE POLICY "permissions_update_document_owner_only"
  ON public.permissions
  FOR UPDATE
  USING (
    public.is_document_owner(document_id, public.current_user_uid())
  )
  WITH CHECK (
    public.is_document_owner(document_id, public.current_user_uid())
  );

-- DELETE: Chủ sở hữu tài liệu có thể thu hồi quyền, hoặc người được chia sẻ có thể tự rời bỏ quyền truy cập
CREATE POLICY "permissions_delete_owner_or_self"
  ON public.permissions
  FOR DELETE
  USING (
    shared_with_uid = public.current_user_uid()
    OR public.is_document_owner(document_id, public.current_user_uid())
  );
