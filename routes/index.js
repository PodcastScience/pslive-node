
/*
 * GET home page.
 */

exports.admin = function(req, res){
  res.render('admin', { title: 'Admin' });
};

exports.index = function(req, res){
  res.render('index', { title: 'PodcastScience Live' });
};

exports.presentation = function(req, res){
  res.render('presentation', { title: 'PodcastScience Live' });
};