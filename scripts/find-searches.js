/**
 * hack script to search google completions for 'definition of X'
 * 
 * Note that this'll be biased because Google bubbles search results, but will
 * nevertheless produce a list of things that at least some people have searched
 * for in the past.
 */

seen = {};
terms = [];
history = {};

function complete(term) {
  var
    xhr = new XMLHttpRequest(),
    url = 'http://www.google.com/s?q=--term--&output=search';
  url = url.replace('--term--', encodeURIComponent('definition of ' + term));
  xhr.open('GET', url, true);
  xhr.onreadystatechange = function(e) {
    if (this.readyState == 4 && this.status == 200) {
      eval(xhr.responseText);
    }
  };
  xhr.send();
  return xhr;
}

window.google.ac.h = function(data){
  data[1].forEach(function(tuple){
    var m = (tuple[0]||'').match(/^definition of ([a-z]{2,})$/);
    if (m && !(m[1] in seen)) {
      seen[m[1]] = true;
      terms[terms.length] = m[1];
    }
  });
  doNext();
}

stack = 'abcdefghijklmnopqrstuvwxyz'.split('');
stack.unshift('');

function doNext() {
  if (stack.length) {
    next = stack.shift();
    history[next] = true;
    complete(next);
  }
}

doNext();

/* Fills 'terms' array with something like this:
love
insanity
culture
swag
science
derivative
mass
volume
marriage
alcoholic
art
addiction
arbitrage
bullying
bigot
bipolar
bias
beauty
biology
business
bigotry
communism
character
capitalism
chemistry
cognitive
congruent
civilization
democracy
density
diversity
definition
dork
dude
depression
douchebag
ethics
economics
element
energy
epic
evolution
empathy
ethos
epiphany
family
friendship
faith
friend
federalism
factor
fruit
fascism
foreshadowing
grace
globalization
government
geography
gender
genre
gdp
god
goal
history
hypothesis
hipster
health
hero
humble
happiness
humility
hypocrite
honor
irony
integrity
integer
innovation
isotope
imagery
identity
ignorance
justice
jealousy
joy
judgement
juxtaposition
jaded
jerk
jihad
job
karma
kosher
knowledge
kryptonite
kismet
keen
kindness
kinesthetic
leadership
life
liberal
loyalty
legacy
law
latino
literature
leader
matter
marketing
metaphor
multiple
mean
music
median
names
namaste
nursing
neurotic
narcissism
nucleus
nationalism
noun
normal
obesity
organic
oxymoron
osmosis
observation
objective
onomatopoeia
ocd
oppression
prejudice
physics
philosophy
plot
politics
paradox
plagiarism
psychology
quality
qi
queer
quotient
quirky
quantitative
qualitative
que
quadrilateral
ratchet
respect
religion
racism
race
republican
republic
relationship
revolution
socialism
sociopath
success
stress
sport
sustainability
theory
terrorism
theme
technology
trolling
touche
trust
unemployment
unity
urban
undermine
ubiquitous
utopia
url
values
virtue
variable
verb
vintage
velocity
veteran
work
weight
worship
wellness
war
wisdom
weather
xi
xenophobia
xerxes
xoxo
xml
xylem
yolo
yacht
yoga
yield
yelling
yar
yuri
za
zealous
zen
zombie
zee
ziggurat
zeitgeist
zion
zionist
zeal
*/
