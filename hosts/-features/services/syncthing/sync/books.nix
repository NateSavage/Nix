{
  services.syncthing.settings.folders = {
    "books" = {
      id = "nate-books";
      path = "~/sync/books";
      type = "sendreceive";
      devices = [ "archive-server" ];
    };
  };
}
