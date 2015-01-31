@Kodi.module "AlbumApp.Show", (Show, App, Backbone, Marionette, $, _) ->

  API =

    ## Return a set of albums with songs.
    ## Songs is expected to be an array of song collections
    ## keyed by albumid. The only thing that should be calling this is artists.
    getAlbumsFromSongs: (songs) ->
      albumsCollectionView = new Show.WithSongsCollection()
      ## What happens when we add a child to this mofo
      albumsCollectionView.on "add:child", (albumView) ->
        App.execute "when:entity:fetched", album, =>
          model = albumView.model
          ## Add the teaser.
          teaser = new Show.AlbumTeaser model: model
          albumView.regionMeta.show teaser
          ## Add the songs.
          songView = App.request "song:list:view", songs[model.get('albumid')]
          albumView.regionSongs.show songView
      ## Loop over albums/song collections
      for albumid, songCollection of songs
        ## Get the album.
        album = App.request "album:entity", albumid, success: (album) ->
          albumsCollectionView.addChild album, Show.WithSongsLayout
      ## Return the collection view
      albumsCollectionView


  ## When viewing a full page we call the controller
  class Show.Controller extends App.Controllers.Base

    ## The Album page.
    initialize: (options) ->
      id = parseInt options.id
      console.log id
      album = App.request "album:entity", id
      ## Fetch the artist
      App.execute "when:entity:fetched", album, =>
        ## Set background image.
        App.execute "images:fanart:set", album.get('fanart')
        ## Get the layout.
        @layout = @getLayoutView album
        ## Ensure background removed when we leave.
        @listenTo @layout, "destroy", =>
          App.execute "images:fanart:set", ''
        ## Listen to the show of our layout.
        @listenTo @layout, "show", =>
          @getMusic id
          @getDetailsLayoutView album
        ## Add the layout to content.
        App.regionContent.show @layout

    ## Get the base layout
    getLayoutView: (album) ->
      new Show.PageLayout
        model: album

    ## Build the details layout.
    getDetailsLayoutView: (album) ->
      headerLayout = new Show.HeaderLayout model: album
      @listenTo headerLayout, "show", =>
        teaser = new Show.AlbumDetailTeaser model: album
        detail = new Show.Details model: album
        headerLayout.regionSide.show teaser
        headerLayout.regionMeta.show detail
      @layout.regionHeader.show headerLayout

    ## Get a list of all the music for this artist parsed into albums.
    getMusic: (id) ->
      options =
        filter: {albumid: id}
      ## Get all the songs and parse them into sepetate album collections.
      songs = App.request "song:filtered:entities", options
      App.execute "when:entity:fetched", songs, =>
        albumView = new Show.WithSongsLayout()
        songView = App.request "song:list:view", songs
        @listenTo albumView, "show", =>
          albumView.regionSongs.show songView
        @layout.regionContent.show albumView


  ## Return a set of albums with songs.
  App.reqres.setHandler "albums:withsongs:view", (songs) ->
    API.getAlbumsFromSongs songs

