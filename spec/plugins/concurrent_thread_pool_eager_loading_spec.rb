# frozen_string_literal: true

require "concurrent"

CONCURRENT_EAGER_DB_URL = ENV.fetch("DB_URL", "postgres:///sequel_plugins")

def make_concurrent_eager_db
  Sequel.connect(CONCURRENT_EAGER_DB_URL).tap { |d| d.extension(:concurrent_thread_pool) }
end

RSpec.describe "concurrent_thread_pool_eager_loading plugin" do
  let(:db) { make_concurrent_eager_db }
  let(:artist_class) do
    klass = Class.new(Sequel::Model(db[:cel_artists]))
    klass.plugin :concurrent_thread_pool_eager_loading
    klass.one_to_many :albums, class: album_class, key: :artist_id
    klass
  end
  let(:album_class) do
    klass = Class.new(Sequel::Model(db[:cel_albums]))
    klass.plugin :concurrent_thread_pool_eager_loading
    klass.many_to_one :artist, class_name: "Artist"
    klass.one_to_many :tracks, class: track_class, key: :album_id
    klass
  end
  let(:track_class) do
    Class.new(Sequel::Model(db[:cel_tracks]))
  end

  before do
    setup_db = make_concurrent_eager_db

    setup_db.create_table(:cel_artists) do
      primary_key :id
      String :name, null: false
    end

    setup_db.create_table(:cel_albums) do
      primary_key :id
      String :title, null: false
      foreign_key :artist_id, :cel_artists
    end

    setup_db.create_table(:cel_tracks) do
      primary_key :id
      String :name, null: false
      foreign_key :album_id, :cel_albums
    end

    artist = setup_db[:cel_artists].returning(:id).insert(name: "Artist A").first[:id]
    album1 = setup_db[:cel_albums].returning(:id)
                                  .insert(title: "Album 1", artist_id: artist).first[:id]
    album2 = setup_db[:cel_albums].returning(:id)
                                  .insert(title: "Album 2", artist_id: artist).first[:id]
    setup_db[:cel_tracks].insert(name: "Track 1", album_id: album1)
    setup_db[:cel_tracks].insert(name: "Track 2", album_id: album1)
    setup_db[:cel_tracks].insert(name: "Track 3", album_id: album2)

    setup_db.disconnect
  end

  after do
    cleanup_db = make_concurrent_eager_db
    cleanup_db.drop_table(:cel_tracks, :cel_albums, :cel_artists)
    cleanup_db.disconnect
  end

  after { db.disconnect rescue nil }

  describe "#eager_load_concurrently" do
    it "loads multiple associations concurrently" do
      albums = album_class.eager_load_concurrently.eager(:tracks).all
      expect(albums.length).to eq(2)
      expect(albums.flat_map(&:tracks).length).to eq(3)
    end

    it "sets eager_load_concurrently option on dataset" do
      ds = album_class.eager_load_concurrently
      expect(ds.opts[:eager_load_concurrently]).to be(true)
    end
  end

  describe "#eager_load_serially" do
    it "loads associations serially even when always: true" do
      album_class.plugin :concurrent_thread_pool_eager_loading, always: true
      albums = album_class.eager_load_serially.eager(:tracks).all
      expect(albums.length).to eq(2)
      expect(albums.flat_map(&:tracks).length).to eq(3)
    end

    it "sets eager_load_concurrently option to false" do
      ds = album_class.eager_load_serially
      expect(ds.opts[:eager_load_concurrently]).to be(false)
    end
  end

  describe "always: true option" do
    before { album_class.plugin :concurrent_thread_pool_eager_loading, always: true }

    it "makes concurrent loading the default" do
      expect(album_class.always_eager_load_concurrently?).to be(true)
    end

    it "loads associations correctly without explicit eager_load_concurrently" do
      albums = album_class.eager(:tracks).all
      expect(albums.flat_map(&:tracks).length).to eq(3)
    end
  end

  describe "single association" do
    it "does not use threads (no mutex set)" do
      # Single association: perform_eager_loads short-circuits, no concurrent execution
      albums = album_class.eager_load_concurrently.eager(:tracks).all
      expect(albums.flat_map(&:tracks).length).to eq(3)
    end
  end

  describe "concurrent execution" do
    it "loads associations correctly when multiple present" do
      albums = album_class.eager_load_concurrently.eager(:tracks).all
      artists = artist_class.eager_load_concurrently.eager(:albums).all

      expect(albums.flat_map(&:tracks).length).to eq(3)
      expect(artists.flat_map(&:albums).length).to eq(2)
    end
  end

  describe "inheritance" do
    it "subclass inherits always_eager_load_concurrently setting" do
      album_class.plugin :concurrent_thread_pool_eager_loading, always: true
      subclass = Class.new(album_class)
      expect(subclass.always_eager_load_concurrently?).to be(true)
    end
  end
end
