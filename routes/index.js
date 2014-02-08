
/*
 * GET home page.
 */

exports.admin = function(req, res){
  res.render('admin', { title: 'Admin' });
};

exports.index = function(req, res){
  res.render('index', { title: 'PodcastScience Live' });
};

exports.indexh5 = function(req, res){
  res.render('indexh5', { title: 'PodcastScience Live' });
};
