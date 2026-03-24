var gulp = require('gulp');
var uglify = require('gulp-uglify');
var cleanCSS = require('gulp-clean-css');
var concat = require('gulp-concat');
// var minify = require('gulp-html-minifier');
const { minify } = require("html-minifier-terser");
const through = require("through2");
var merge = require('merge-stream');
var replace = require('gulp-replace');
var rename = require("gulp-rename");
var jsonminify = require('gulp-jsonminify');

var DEST = './public';

function minifyHTML() {
  return through.obj(async function (file, enc, cb) {
    if (file.isBuffer()) {
      try {
        const result = await minify(file.contents.toString(), {
          collapseWhitespace: true,
          minifyCSS: true,
          minifyJS: true,
          removeComments: true,
        });

        file.contents = Buffer.from(result);
      } catch (err) {
        return cb(err);
      }
    }

    cb(null, file);
  });
}

gulp.task('default', function() {

  var html = gulp.src('./dev.html')
    .pipe(replace(/\.\/src/g, "./public" ))
    .pipe(minifyHTML())
    .pipe(rename("index.html"))
    .pipe(gulp.dest('./'));

  var css = gulp.src('src/styles.css')
    .pipe(cleanCSS())
    .pipe(gulp.dest(DEST));

  var js = gulp.src(['src/tetris.js', "src/audio.js", "src/play.js", "src/onload.js"])
    .pipe(replace(/\.\/src/g, "./public" ))
    .pipe(concat('all.js'))
    .pipe(gulp.dest(DEST));

  var sw = gulp.src('src/sw.js')
    .pipe(uglify())
    .pipe(gulp.dest('./'));

  var poly = gulp.src('src/serviceworker-cache-polyfill.js')
    .pipe(uglify())
    .pipe(gulp.dest(DEST));

  return merge(html, css, js, sw, poly);
});
