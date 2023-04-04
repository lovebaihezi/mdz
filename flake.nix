{
  description = "mdz will generate Latex from Markdown";

  outputs = { self, nixpkgs }: {

    packages.x86_64-linux.neovim = nixpkgs.legacyPackages.x86_64-linux.neovim;
    
    packages.x86_64-linux.helix = nixpkgs.legacyPackages.x86_64-linux.helix;

    packages.x86_64-linux.hello = nixpkgs.legacyPackages.x86_64-linux.hello;

    packages.x86_64-linux.default = self.packages.x86_64-linux.hello;

  };
}
