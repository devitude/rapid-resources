collection_fields = page.collection_fields.map{ |f| [*f].first }
json.columns collection_fields.collect { |field| {id: field, title: page.field_title(field)} }

json.data items do |item|
  json.id item.id
  json.attributes do
    page.collection_fields.each do |f|
      json.set! f, resource_field(page, item, f, nil)
    end
    page.json_fields.each do |f|
      json.set! f, resource_field(page, item, f, nil)
    end
  end

  json.links page.collection_item_links(item)
  # json.links do
  #   json.edit edit_candidates_import_batch_item_path(@import_batch.id, item.id)
  #   json.editModal edit_candidates_import_batch_item_path(@import_batch.id, item.id, modal: '1', format: :json)
  # end
end
