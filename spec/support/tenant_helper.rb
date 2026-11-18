# frozen_string_literal: true

module TenantHelper
  def tenant_db(id = SPEC_TENANT_ID)
    MyErp::DB.tenant(id)
  end

  def tenant_path(id = SPEC_TENANT_ID)
    MyErp::DB.tenant_path(id)
  end

  def with_tenant(id = SPEC_TENANT_ID, &block)
    MyErp::DB.with_tenant(id, &block)
  end
end
