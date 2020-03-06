Sequel.migration do
  change do
    create_table :users do
      primary_key :id
      String :username, null: false
      String :first_name, null: false
      String :last_name, null: false
      String :chat_id, null: false
      DateTime :created_at, null: false
    end

    alter_table :users do
      add_index :chat_id, unique: true
    end
  end
end
