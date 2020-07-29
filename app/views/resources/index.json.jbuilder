collection_fields = page.collection_fields.map{ |f| [*f].first }
columns = collection_fields.map do |field|
  # Fixme: leave only CollectionField handling
  if field.is_a?(RapidResources::CollectionField)
    {id: field.name, title: field.title}
  else
    {id: field, title: page.field_title(field)}
  end
end

json.columns columns

json.data items do |item|
  json.id item.id
  json.attributes do
    page.collection_fields.each do |f|
      f_name = f.is_a?(RapidResources::CollectionField) ? f.name : f
      json.set! f_name, resource_field(page, item, f_name, nil)
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
