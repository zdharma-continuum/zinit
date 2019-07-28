for file in site/*/index.html
do 
  gsed -i '$ d' $file
  gsed -i '$ d' $file
  echo '<link href="../../highlight/style.css" rel="stylesheet" />
  <script src="../../highlight/highlight.pack.js"></script>
  <script>
  function highlightCode() {
      var pres = document.querySelectorAll("pre>code");
      for (var i = 0; i < pres.length; i++) {
	  hljs.highlightBlock(pres[i]);
      }
  }
  highlightCode();
  </script>

  </body>
</html>' >> $file
done
