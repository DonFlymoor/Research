var htmlTagValidator = require('html-tag-validator')
  , fs = require('fs')
  , path = require('path')
  , vm = require('vm')
  ;

var uiLocation = 'ui/'
  , appLocation = `${uiLocation}modules/apps/`
  , htmlChecksOutMsg = 'The document validates according to the specified schema(s).\n'
  ;

// from https://stackoverflow.com/questions/18112204/get-all-directories-within-directory-nodejs
function isDirectory (source) {
  return fs.lstatSync(source).isDirectory()
}
function getDirectories (source) {
  return fs.readdirSync(source).map(name => path.join(source, name)).filter(isDirectory)
}

function getAppHtml (baseFolder, modules) {
  var res = {};
  for (var key in modules) {
    var config = modules[key]()
    if (config.template !== undefined) {
      res[key] = config.template;
    } else if (config.templateUrl !== undefined) {
      res[key] = fs.readFileSync(`${baseFolder}${config.templateUrl}`, {encoding: 'utf-8'})
    }
    res[key] = res[key].replace(/<svg(.|\s)*?<\/svg>/gm, '') // exclude svg bits as the validator is not cabaple of handling them
  }
  return res;
}


describe('valid apps', function () {
  const sandbox =
    { angular:
      { module: () => (
        { directive: (name, dep) =>
          { sandbox.dirs[name] = Array.isArray(dep) ? dep[dep.length - 1] : dep;
            return sandbox.angular.module();
          }
        , value: sandbox.angular.module
        , constant: sandbox.angular.module
        })
      }
    , dirs: {}
    };
  vm.createContext(sandbox);
  // TODO: check if it works that we share one context
  // idea is that it speeds up the testing, but if jasmine runs in parallel, this might screw and might have some side effects, where we only check the last app (see accessing var i in async loop)

  var folders = getDirectories(appLocation);
  // var folders = ['ui/modules/apps/RaceRealtimeDisplay', 'ui/modules/apps/TaxiStats', 'ui/modules/apps/ClutchThermalDebug'];
  folders.forEach(folder => {
    it(`valid app ${folder}/app.js`, function (done) {
      let appjs = `${folder}/app.js`
        , dirs = {}
        ;

      if (fs.existsSync(appjs)) {
        try {
          sandbox.dirs = {};
          vm.runInContext(fs.readFileSync(appjs), sandbox);
          dirs = sandbox.dirs;
          expect(true).toBe(true); // since there is no succed function
        } catch (err) {
          fail(err)
        }
        let htmls = getAppHtml(uiLocation, dirs);
        if (Object.keys(dirs).length === 0) {
          console.debug(appjs, 'does not declare a directive')
        }

        var promises = [];

        for (var key in htmls) {
          let all = [/^((ng-*)|(bng-.*)|(aria-.*)|(md-*)|(layout.*)$)/, 'flex']
            , options =
              // { tags:
              // { normal: [] }
              { attributes:
                // gatherd so far: mixed can but doesn't have to have an argument, normal requires one
                { '_':
                  { mixed: all }
                , 'table':
                  { normal: [ 'align', 'bgcolor', 'border', 'cellpadding', 'cellspacing', 'frame', 'rules', 'summary', 'width'] }
                , 'td':
                  { normal: [ 'height', 'width', 'bgcolor'] }
                , 'th':
                  { normal: [ 'height', 'width', 'bgcolor'] }
                , 'md-slider':
                  { mixed: all
                  , normal: ['min', 'max', 'step', 'style', 'value']
                  }
                , 'binding':
                  { mixed: all
                  , normal : ['action', 'key', 'device', 'style']
                  }
                }
              }
          promises.push(new Promise((resolve) => {
            htmlTagValidator(htmls[key], options, (error, ast) => {
              var ignore =
                [ 'The link element goes only in the head section of an HTML document'
                , 'If the scoped attribute is not used, each style tag must be located in the head section'
                ]
              if (error && ignore.indexOf(error.message) === -1) {
                fail(error);
              } else {
                expect(true).toBe(true); // since there is no succed function
              }
              resolve();
            })
          }))
        }
        Promise.all(promises).then(done)
      } else {
        console.debug(appjs, 'not existing')
        done();
      }
    })
  })
})