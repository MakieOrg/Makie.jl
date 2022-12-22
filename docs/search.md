@def title = "Search"
@def hidden = true
@def searchpage = true

## Search
~~~
<div class="stork-wrapper" id="search-page">
  <input id="search-input" data-stork="makiesearch" class="stork-input" placeholder="Search documentation"/>
  <div data-stork="makiesearch-output" class="stork-output-title"></div>
</div>

<script>
  // this is a hacky way make stork update the results since updating is not possible through the stork API (yet)
  function sleep(ms) {
      return new Promise(resolve => setTimeout(resolve, ms));
  }
  sleep(200).then(() => {
    var search_input = new URLSearchParams(window.location.search).get('q');
    var input = document.querySelector(`input[data-stork="makiesearch"]`);
    input.value = search_input;
    input.focus()
    input.dispatchEvent(new Event("input"));
  })
</script>
~~~