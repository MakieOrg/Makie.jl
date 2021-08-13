ul = document.querySelector("#navbar ul");

function collapse_if_inactive(ul){
    let active = false;

    console.log(ul.children.length);
    for (li of ul.children){
        let a = li.querySelector("a.active");
        if (a !== null){
            active = true;
            console.log("active");
        }
        let cul = li.querySelector("ul");
        if (cul !== null){
            active = active || collapse_if_inactive(cul);
            if (!active){
                cul.classList.add("collapsed");
            }
        }
    }
    
    return active;
}

collapse_if_inactive(ul);

