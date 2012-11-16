module Exlibris
  module Primo
    module WebService
      module Request
        # 
        # 
        # 
        class Tags < UserRecord
          self.abstract = true
        end

        # 
        # 
        # 
        class GetTags < Tags; end

        # 
        # 
        # 
        class GetAllMyTags < Tags
          self.remove_base_elements :doc_id
        end

        # 
        # 
        # 
        class GetTagsForRecord < Tags
          self.remove_base_elements :user_id
        end

        # 
        # 
        # 
        class RemoveTag < Tags
          self.add_base_elements :value
        end

        # 
        # 
        # 
        class GetUserTags < Tags
          self.remove_base_elements :doc_id
        end
      end
    end
  end
end