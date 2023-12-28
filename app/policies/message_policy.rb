class MessagePolicy < ApplicationPolicy
    # See https://actionpolicy.evilmartians.io/#/writing_policies
    #
    # def index?
    #   true
    # end
    #
    # def update?
    #   # here we can access our context and record
    #   user.admin? || (user.id == record.user_id)
    # end
  
    def index?
      generate_context(user)
      (user.admin? && user.permissions.where(permission: "groups").any?)
    end

    def create?
      generate_context(user)
      (user.admin? && user.permissions.where(permission: "groups").any?) || ( UNLEASH.is_enabled?("beta", @unleash_context) && user.id == record.user_id && allowed_to?(:show?, record.chat) )
    end
  
    def show?
      generate_context(user)
      (user.admin? && user.permissions.where(permission: "groups").any?) || ["listed", "unlisted", "pinned"].include?(record.chat.group_chat.publicity) || record.account == user
    end
  
    def update?
      generate_context(user)
      UNLEASH.is_enabled? "beta", @unleash_context && record.account == user || (user.admin? && user.permissions.where(permission: "groups").any?)
    end
    
    def destroy?
      generate_context(user)
      user.admin? && user.permissions.where(permission: "groups").any?
    end
    
    # Scoping
    # See https://actionpolicy.evilmartians.io/#/scoping
    #
    # relation_scope do |relation|
    #   next relation if user.admin?
    #   relation.where(user: user)
    # end

    def generate_context(user)
      @unleash_context = Unleash::Context.new(
        user_id: user ? user.id : nil,
        betakey: (user && user.beta_code.present?) ? user.beta_code.code : "",
        admin: (user && user.admin?) ? true : false,
        properties: { 
            betakey: (user && user.beta_code.present?) ? user.beta_code.code : "",
            admin: (user && user.admin?) ? true : false
        }
      )
    end
  end
  