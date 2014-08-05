module Trello
  # Organizations are useful for linking members together.
  class Organization < BasicData
    register_attributes :id, :name, :display_name, :description, :website,
      :readonly => [ :id ]
    validates_presence_of :id, :name

    include HasActions

    class << self
      # Find an organization by its id.
      def find(id, params = {})
        client.find(:organization, id, params)
      end
    end
    
    def save
      return update! if id

      fields = { :displayName => display_name }
      fields.merge!(:name => name) if name
      fields.merge!(:description => description) if description
      fields.merge!(:website => website) if website

      client.post("/organizations", fields).json_into(self)
    end

    def update!
      fail "Cannot save new instance." unless self.id

      @previously_changed = changes
      @changed_attributes.clear

      client.put("/organizations/#{self.id}/", {
        :name        => attributes[:name],
        :displayName => attributes[:display_name],
        :desc => attributes[:description],
        :website     =>  attributes[:website]
      }).json_into(self)
    end

    # Update the fields of an organization.
    #
    # Supply a hash of string keyed data retrieved from the Trello API representing
    # an Organization.
    def update_fields(fields)
      attributes[:id]           = fields['id']
      attributes[:name]         = fields['name']
      attributes[:display_name] = fields['displayName']
      attributes[:description]  = fields['desc']
      attributes[:website]          = fields['website']
      self
    end

    # Returns a list of boards under this organization.
    def boards
      boards = client.get("/organizations/#{id}/boards/all").json_into(Board)
      MultiAssociation.new(self, boards).proxy
    end

    # Returns an array of members associated with the organization.
    def members(params = {})
      members = client.get("/organizations/#{id}/members/all", params).json_into(Member)
      MultiAssociation.new(self, members).proxy
    end

    # :nodoc:
    def request_prefix
      "/organizations/#{id}"
    end
  end
end
