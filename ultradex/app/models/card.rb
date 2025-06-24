# ultradex/app/models/card.rb
class Card
  include ActiveModel::Model
  include ActiveModel::Attributes # For type casting attributes

  # Define attributes based on REQUIREMENTS.md Section 2.3.1
  # and the card_uuid itself.
  attribute :card_uuid, :string
  attribute :pokemon_species_name, :string
  attribute :card_name, :string
  attribute :national_pokedex_number, :string # Stored as string, e.g., "025"
  attribute :original_set_id, :string
  attribute :set_name, :string
  attribute :series_name, :string
  attribute :release_date, :date # Or :string if not always parseable
  attribute :card_number_in_set, :string
  attribute :rarity, :string
  attribute :card_type, :string # e.g., "Pokémon", "Trainer", "Energy"
  attribute :pokemon_types, :string # Comma-separated string e.g., "Grass, Psychic" or JSON array string
  attribute :hp, :integer # Or :string if it can contain non-numeric values like "None"
  attribute :illustrator_name, :string
  attribute :image_url_small, :string
  attribute :image_url_large, :string
  attribute :approximate_price_usd, :float # Or :decimal for precision
  attribute :last_price_update_timestamp, :integer # Unix timestamp
  attribute :notes, :string
  attribute :variant_code, :string # From card_uuid
  attribute :frame_code, :string # From card_uuid
  attribute :set_release_number, :string # From card_uuid, though stored as integer in requirements

  # Store the raw hash from Redis for inspection or if not all fields are modeled
  attr_reader :raw_data

  # Validations (optional for now, but ActiveModel::Model allows them)
  validates :card_uuid, presence: true
  validates :card_name, presence: true
  validates :national_pokedex_number, presence: true # Example

  def initialize(attributes = {})
    super(attributes)
    @raw_data = attributes.freeze # Store the original attributes hash

    # Manual type casting or parsing for specific fields if ActiveModel::Attributes isn't sufficient
    # For example, if pokemon_types is a JSON string that needs to be an array:
    # if attributes[:pokemon_types].is_a?(String)
    #   begin
    #     self.pokemon_types = JSON.parse(attributes[:pokemon_types])
    #   rescue JSON::ParserError
    #     # Keep as string if not valid JSON, or handle error
    #   end
    # end
    # However, ActiveModel::Attributes might handle basic types well.
    # For price, ensure it's a float
    # self.approximate_price_usd = attributes[:approximate_price_usd].to_f if attributes[:approximate_price_usd]
  end

  # Helper to access the Redis client
  def self.redis
    RedisScripts.redis_client # Uses the client from RedisScripts module
  end

  # Expose the RedisScripts execution helper at the class level for convenience
  def self.execute_script(script_name, keys: [], argv: [])
    RedisScripts.execute(script_name, keys: keys, argv: argv)
  end

  # Instance method to access redis client if needed, though less common for model instances
  def redis
    self.class.redis
  end

  # --- Methods for UUID generation/parsing ---
  # card_uuid format: [set_release_number]-[pokedex_number]-[variant_code]-[frame_code]

  def self.generate_uuid(set_release_number:, pokedex_number:, variant_code:, frame_code:)
    # Ensure pokedex_number is padded if necessary (e.g., 3 digits with leading zeros)
    # Assuming pokedex_number is passed as a string already formatted.
    # Add validation or formatting here if needed.
    unless pokedex_number.match?(/^\d{3,}$/) # Example: 001, 025, 101
        # This is a simple check. REQUIREMENTS.md says "Use leading zeros to ensure consistent length if desired (e.g., 3 digits)."
        # For now, we assume it's passed correctly.
    end
    "#{set_release_number}-#{pokedex_number}-#{variant_code.upcase}-#{frame_code.upcase}"
  end

  def parse_uuid
    return nil unless card_uuid && !card_uuid.empty?
    parts = card_uuid.split('-')
    return nil unless parts.length == 4
    {
      set_release_number: parts[0],
      pokedex_number: parts[1],
      variant_code: parts[2],
      frame_code: parts[3]
    }
  end

  # Override attribute readers if specific parsing from @raw_data is needed
  # For example, if approximate_price_usd is stored as string in Redis but needs to be float:
  # def approximate_price_usd
  #   @raw_data[:approximate_price_usd].to_f
  # end

  # def release_date
  #   # ActiveModel::Attributes should handle :date type correctly if string is standard
  #   # Otherwise, parse manually:
  #   Date.parse(@raw_data[:release_date]) if @raw_data[:release_date].present?
  # rescue ArgumentError
  #   @raw_data[:release_date] # return original string if parsing fails
  # end

  # --- Class Methods for Data Interaction ---

  def self.find(uuid)
    json_data = execute_script(:get_card, keys: [uuid])
    return nil unless json_data

    begin
      data = JSON.parse(json_data)
      # The card_uuid is not part of the hash in Redis, it's the key.
      # So, we add it back to the data hash for the model.
      data['card_uuid'] = uuid
      new(data)
    rescue JSON::ParserError => e
      Rails.logger.error "JSON::ParserError in Card.find for UUID #{uuid}: #{e.message}"
      nil
    end
  end

  # Creates a new card in Redis.
  # Attributes should include all necessary fields for the card hash
  # and components for the UUID if card_uuid is not directly provided.
  def self.create(attributes)
    card_attributes = attributes.with_indifferent_access

    # Generate UUID if not provided and components are present
    uuid = card_attributes[:card_uuid]
    if uuid.blank? && card_attributes.values_at(:set_release_number, :pokedex_number, :variant_code, :frame_code).all?(&:present?)
      uuid = generate_uuid(
        set_release_number: card_attributes[:set_release_number],
        pokedex_number: card_attributes[:pokedex_number],
        variant_code: card_attributes[:variant_code],
        frame_code: card_attributes[:frame_code]
      )
      card_attributes[:card_uuid] = uuid
    elsif uuid.blank?
      raise ArgumentError, "card_uuid or its components (set_release_number, pokedex_number, variant_code, frame_code) must be provided"
    end

    # Ensure components from UUID are part of the hash data sent to Redis, as per REQUIREMENTS.md
    parsed_uuid_components = new(card_uuid: uuid).parse_uuid
    card_attributes[:set_release_number] ||= parsed_uuid_components[:set_release_number]
    card_attributes[:national_pokedex_number] ||= parsed_uuid_components[:pokedex_number] # national_pokedex_number is often part of UUID
    card_attributes[:variant_code] ||= parsed_uuid_components[:variant_code]
    card_attributes[:frame_code] ||= parsed_uuid_components[:frame_code]


    # The Lua script `add_card.lua` expects ARGV[1] to be a JSON string of card data.
    # The `card_uuid` itself is KEYS[1]. So, don't include card_uuid in the JSON data payload.
    data_for_json = card_attributes.except(:card_uuid)

    # Convert all values to string as Lua script might expect strings or Redis stores them as such.
    # The add_card.lua script uses tostring(value) for all hash values.
    data_for_json.transform_values!(&:to_s)

    card_data_json = data_for_json.to_json

    result = execute_script(:add_card, keys: [uuid], argv: [card_data_json])

    if result == "OK"
      new(card_attributes) # Return new card instance
    else
      Rails.logger.error "Failed to create card with UUID #{uuid}. Redis script returned: #{result}"
      # Consider creating an errors object on a temporary instance or returning the result string
      card = new(card_attributes)
      card.errors.add(:base, "Failed to save card to Redis: #{result}")
      card # Return the instance with errors
    end
  end

  def self.find_by_pokemon(pokedex_number)
    uuids = execute_script(:find_cards_by_pokemon, keys: [pokedex_number]) || []
    uuids.map { |uuid| find(uuid) }.compact # Fetch full card objects
  end

  def self.find_by_set(original_set_id)
    uuids = execute_script(:find_cards_by_set, keys: [original_set_id]) || []
    uuids.map { |uuid| find(uuid) }.compact
  end

  def self.find_by_illustrator(illustrator_name)
    # Normalization should match the one in add_card.lua
    normalized_name = illustrator_name.to_s.downcase.gsub(/\s+/, "_").gsub(/[^A-Za-z0-9_]+/, "")
    if normalized_name.empty?
      Rails.logger.warn "Normalized illustrator name is empty for input: #{illustrator_name}"
      return []
    end
    uuids = execute_script(:find_cards_by_illustrator, keys: [normalized_name]) || []
    uuids.map { |uuid| find(uuid) }.compact
  end

  # --- Instance Methods ---

  # Updates the price of the card in Redis and on the instance.
  #
  # @param new_price_usd [Float, String] The new approximate price in USD.
  # @param timestamp [Integer] The Unix timestamp for when the price was updated. Defaults to current time.
  # @return [Boolean] True if successful, false otherwise.
  def update_price(new_price_usd, timestamp = Time.now.to_i)
    return false unless card_uuid.present? # Cannot update if UUID is missing

    result = self.class.execute_script(
      :update_card_price,
      keys: [card_uuid],
      argv: [new_price_usd.to_s, timestamp.to_s] # Lua script expects string arguments
    )

    if result == "OK"
      # Update instance attributes
      self.approximate_price_usd = new_price_usd.to_f
      self.last_price_update_timestamp = timestamp
      @raw_data = @raw_data.merge( # Also update raw_data if it's being kept in sync
        'approximate_price_usd' => new_price_usd.to_f,
        'last_price_update_timestamp' => timestamp
      ).freeze
      clear_changes_information # From ActiveModel::Dirty if it were included more deeply
      true
    else
      Rails.logger.error "Failed to update price for card UUID #{card_uuid}. Redis script returned: #{result}"
      errors.add(:base, "Failed to update price in Redis: #{result}")
      false
    end
  end

  # A general save method.
  # Handles both creation of new records (if card_uuid can be determined)
  # and updates to existing records.
  def save
    return false unless valid? # Leverage ActiveModel::Validations

    # Determine if it's a new record or an update
    # If card_uuid is blank, try to generate it.
    if card_uuid.blank?
      if attributes_for_uuid_generation_present?
        self.card_uuid = self.class.generate_uuid(
          set_release_number: self.set_release_number,
          pokedex_number: self.national_pokedex_number, # Use national_pokedex_number for UUID consistency
          variant_code: self.variant_code,
          frame_code: self.frame_code
        )
      else
        errors.add(:base, "Cannot save new record: card_uuid is blank and components for generation are missing.")
        return false
      end
    end

    # Now card_uuid should be present. Proceed with add_card script (upsert).
    data_payload = attributes_for_redis

    # The add_card.lua script expects all values as strings.
    # attributes_for_redis returns values in their model types.
    stringified_payload = data_payload.transform_values do |v|
      if v.is_a?(Date) || v.is_a?(Time) || v.is_a?(DateTime)
        v.iso8601 # Consistent string format for dates/times
      else
        v.to_s
      end
    end

    card_data_json = stringified_payload.to_json

    result = self.class.execute_script(:add_card, keys: [self.card_uuid], argv: [card_data_json])

    if result == "OK"
      # Update raw_data to reflect the persisted state
      @raw_data = data_payload.merge('card_uuid' => self.card_uuid).freeze
      clear_changes_information # From ActiveModel::Dirty
      true
    else
      Rails.logger.error "Failed to save/update card with UUID #{self.card_uuid}. Redis script returned: #{result}"
      # If it was a creation attempt where UUID was just generated, clear it so `persisted?` is false.
      # This logic might need refinement based on how errors are handled for new vs. existing.
      # For now, the error is added, and card_uuid remains.
      errors.add(:base, "Failed to save card to Redis: #{result}")
      false
    end
  end

  def attributes_for_uuid_generation_present?
    set_release_number.present? &&
    national_pokedex_number.present? && # Changed from pokedex_number to national_pokedex_number
    variant_code.present? &&
    frame_code.present?
  end

  # To integrate with form helpers or if ActiveModel::Dirty is used
  def persisted?
    # A card is persisted if its UUID is present.
    # A truly robust check might involve verifying it exists in Redis,
    # but for model state, UUID presence is often sufficient.
    # If save fails on a new record, card_uuid might be set then error occurs.
    # Ideally, card_uuid is only non-blank if successfully saved or fetched.
    # The `save` method tries to ensure this.
    card_uuid.present? && errors.empty? # Consider errors empty as part of being "persisted"
  end

  # Required by some form builders if not using ActiveRecord
  def to_key
    persisted? ? [card_uuid] : nil
  end

  def to_model
    self
  end

  # Provides attributes suitable for `Card.create` or for the `add_card` Lua script.
  def attributes_for_redis
    attrs = self.attributes.except('card_uuid', 'raw_data', 'errors', 'validation_context')
    # Ensure UUID components are present from the card_uuid itself
    if card_uuid.present?
      components = parse_uuid
      attrs['set_release_number'] ||= components[:set_release_number]
      attrs['national_pokedex_number'] ||= components[:pokedex_number] # national_pokedex_number is often part of UUID
      attrs['variant_code'] ||= components[:variant_code]
      attrs['frame_code'] ||= components[:frame_code]
    end
    attrs
  end

end
