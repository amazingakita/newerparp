class Message < ApplicationRecord
    self.inheritance_column = 'inheritance_type'

    scope :between, -> (start, finish) {
        where("posted BETWEEN ? AND ?", start, finish)
    }
    
    belongs_to :account, :foreign_key => 'user_id'
    belongs_to :chat_user, query_constraints: [:chat_id, :user_id]
    belongs_to :chat
    has_rich_text :content

    enum render_mode: [ :bbcode, :actiontext ]

    validate :attachments_valid
    validate :has_some_content
    validate :content_length

    has_rich_text :content

    after_create_commit -> { 
        broadcast_append_to "chat_#{chat.id}"
        chat.last_message = posted
        chat.save
    }
    after_update_commit -> { broadcast_replace_to "chat_#{chat.id}" }
    after_destroy_commit -> { broadcast_remove_to "chat_#{chat.id}" }

    def has_some_content
        return if content? || (!text.nil? && !text.empty?)
        errors.add(:content, "must not be empty")
    end

    def content_length
        return if content? && content.to_s.size < 20000
        errors.add(:content, "must be less than 20,000 characters")
    end

    def attachments_valid
        if content && content.body && content.body.attachments
            content.body.attachments.each do |attach|
                if chat.group_chat? && !chat.group_chat.image_upload
                    errors.add(:files, 'are disallowed in this room') unless chat.group_chat.image_upload
                end
                errors.add(:file, "#{attach.filename} is larger than 10 mb") if attach.byte_size > 1242880
                errors.add(:file, "#{attach.filename} is not an image") unless attach.image? 
                errors.add(:file, "#{attach.filename} is not a supported image type (png, jpeg)") unless attach.content_type == 'image/jpeg' || attach.content_type == 'image/png'
            end
        end
    end
end
