module ParseResource
	module DefaultAttributes
    # aliasing for idiomatic Ruby
    def id; self.objectId rescue nil; end

    def created_at; self.createdAt; end

    def updated_at; self.updatedAt rescue nil; end
	end
end