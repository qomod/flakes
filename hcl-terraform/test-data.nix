{ pkgs, system ? builtins.currentSystem }:
let
  inherit (import ./hcl.nix { inherit pkgs; })
    optional_ optional object list b a _lib mapMerge
    mkVariables mkVariableValues mkBlocks mkBlocks_
    string number bool bb qq
    ;
  inherit (pkgs.lib.attrsets) genAttrs;
  # Tests -----------
  # inspired by Terraform docs
  docsMainTF = mkBlocks {
    terraform = b {
      required_providers = a {
        docker = a {
          source = "kreuzwerker/docker";
          version = "~> 2.22.0";
        };
      };
    };
    resource.b = b { d = b { }; };
    lib = with _lib; a {
      t = tomap [{ a = "b"; c = "d"; }];
      s = abs [ (ceil [ (floor [ (-3.5) ]) ]) ];
    };
  };

  docsType = list (object {
    name = string;
    enabled = optional bool true;
    website = optional
      (object {
        index_document = optional string "index.html";
        error_document = optional string "error.html";
        routing_rules = optional_ string;
      })
      { };
  });

  docsVariablesTF = mkVariables {
    a = { type = object { a = number; }; };
    b = { type = optional string "b"; };
    buckets = { type = docsType; };
    c = { type = optional (optional_ (object { c = optional string ""; })) { }; };
    d = { type = optional_ string; default = "hey"; };
  };

  docsTfvarsTF = mkVariableValues docsVariablesTF {
    a = { a = 100; };
    b = "c";
    buckets = [
      {
        name = "production";
        website = {
          routing_rules =
            ''
              [
                {
                  "Condition" = { "KeyPrefixEquals": "img/" }
                  "Redirect"  = { "ReplaceKeyPrefixWith": "images/" }
                }
              ]
            '';
        };
      }
      {
        name = "archived";
        enabled = false;
      }
      {
        name = "docs";
        website = {
          index_document = "index.txt";
          error_document = "error.txt";
        };
      }
    ];
  };

  # Docker

  appPurescript = "app_purescript";
  appPython = "app_python";
  apps = [ appPurescript appPython ];
  _mod = x: { try = "try_${x}"; path = "path_${x}"; };

  variablesTF = mkVariables (genAttrs apps (app: {
    type = object {
      DIR = optional string "/app";
      DOCKER_PORT = optional number 80;
      HOST = optional string "0.0.0.0";
      NAME = optional string "renamed_${app}";
      HOST_PORT = number;
    };
  }));

  tfvarsTF = mkVariableValues variablesTF {
    "${appPython}" = {
      HOST_PORT = 8002;
    };
    "${appPurescript}" = {
      HOST_PORT = 8003;
    };
  };

  # should place expr A before expr B:
  # if B depends on A (uses its accessors)
  # if we want A to be rendered before B
  mainTF = with _lib;
    mkBlocks_ (tfvarsTF.__)
      (
        {
          terraform = b {
            required_providers = a {
              docker = a {
                source = "kreuzwerker/docker";
                version = "~> 2.22.0";
              };
            };
          };
        }
        // mapMerge apps (app:
          let app_ = _mod app; in
          {
            resource.docker_image =
              {
                "${app_.try}" = b {
                  name = "dademd/${app}:latest";
                  keep_locally = false;
                };
              };
            locals = b {
              "${app_.path}" = abspath [ "${bb path.root}/../../${app}" ];
            };
          }
        )
      )
      (__: with __; mapMerge apps
        (
          app:
          let app_ = _mod app; in
          {
            resource.docker_container."${app_.try}" = b {
              image = docker_image."${app_.try}" "image_id";
              name = "${app_.try}";
              restart = "always";
              volumes = a {
                container_path = var."${app}".DIR;
                host_path = local."${app_.path}";
                read_only = false;
              };
              ports = a {
                internal = var."${app}".DOCKER_PORT;
                external = var."${app}".HOST_PORT;
              };
              env = [ "HOST=${bb var."${app}".HOST}" "PORT=${bb var."${app}".DOCKER_PORT}" ];
              host = b {
                host = "localhost";
                ip = var."${app}".HOST;
              };
            };
          }
        )
      );
in
{
  inherit mainTF tfvarsTF variablesTF;
  inherit docsMainTF docsTfvarsTF docsVariablesTF;
}
