collection_fields = page.collection_fields.map{ |f| [*f].first }

json.columns collection_fields.collect { |field| [field.to_s.camelize(:lower), page.field_title(field)] }
items = items.map do |item|
  item_attributes = Hash[collection_fields.map { |f| [f.to_s.camelize(:lower), resource_field(page, item, f, nil)] }]
  item_attributes[:id] = item.id
  item_attributes[:_links] = {}
  item_attributes
end
json.items items
