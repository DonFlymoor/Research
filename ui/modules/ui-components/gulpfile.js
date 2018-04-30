var gulp = require('gulp')
  , babel = require('gulp-babel')
  , sass = require('gulp-sass')
  , concat = require('gulp-concat')
  , insert = require('gulp-insert')
  , uglify = require('gulp-uglify')
;


gulp.task('sass', function () {
  return gulp.src(['./src/**/*.scss'])
    .pipe(sass.sync().on('error', sass.logError))
    .pipe(concat('bng-components.css'))
    .pipe(gulp.dest('.'));
});

gulp.task('js', function () {
   return gulp.src(['./src/**/*.js'])
     .pipe(concat('bng-components.js'))
     .pipe(insert.prepend("angular.module('beamng.components', []);"))
     .pipe(babel({presets: ['es2015']}))
     .pipe(uglify())
     .pipe(gulp.dest('.'));
});

gulp.task('default', ['sass', 'js']);