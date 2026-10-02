document.addEventListener('DOMContentLoaded', () => {
    const shapesContainer = document.querySelector('.shapes-container');
    const shapes = document.querySelectorAll('.shape');
    let isExpanded = false;

    // Service repository URLs and descriptions
    const serviceUrls = {
        'addie': 'https://github.com/freyja-love-and-magic/addie',
        'aretha': 'https://github.com/freyja-love-and-magic/aretha',
        'bdo': 'https://github.com/freyja-love-and-magic/bdo',
        'continuebee': 'https://github.com/freyja-love-and-magic/continuebee',
        'dolores': 'https://github.com/freyja-love-and-magic/dolores',
        'fount': 'https://github.com/freyja-love-and-magic/fount',
        'joan': 'https://github.com/freyja-love-and-magic/joan',
        'julia': 'https://github.com/freyja-love-and-magic/julia',
        'pref': 'https://github.com/freyja-love-and-magic/pref',
        'sanora': 'https://github.com/freyja-love-and-magic/sanora'
    };

    // Cache management
    const CACHE_KEY = 'github_repo_descriptions';
    const CACHE_EXPIRY = 24 * 60 * 60 * 1000; // 24 hours in milliseconds

    const getCache = () => {
        const cache = localStorage.getItem(CACHE_KEY);
        if (!cache) return null;
        
        try {
            const { timestamp, descriptions } = JSON.parse(cache);
            if (Date.now() - timestamp > CACHE_EXPIRY) {
                localStorage.removeItem(CACHE_KEY);
                return null;
            }
            return descriptions;
        } catch (error) {
            localStorage.removeItem(CACHE_KEY);
            return null;
        }
    };

    const setCache = (descriptions) => {
        const cacheData = {
            timestamp: Date.now(),
            descriptions
        };
        localStorage.setItem(CACHE_KEY, JSON.stringify(cacheData));
    };

    // Fetch repository descriptions
    const fetchRepoDescriptions = async () => {
        // Try to get descriptions from cache first
        const cachedDescriptions = getCache();
        if (cachedDescriptions) {
            // Use cached descriptions
            shapes.forEach(shape => {
                const serviceName = shape.getAttribute('data-service');
                if (serviceName && cachedDescriptions[serviceName]) {
                    const tooltip = document.createElement('div');
                    tooltip.className = 'tooltip';
                    tooltip.textContent = cachedDescriptions[serviceName];
                    shape.appendChild(tooltip);
                }
            });
            return;
        }

        // If no cache, fetch from GitHub API
        const descriptions = {};
        const fetchPromises = [];

        shapes.forEach(shape => {
            const serviceName = shape.getAttribute('data-service');
            if (serviceName && serviceUrls[serviceName]) {
                const repoUrl = serviceUrls[serviceName];
                const repoName = repoUrl.split('/').pop();
                
                const fetchPromise = fetch(`https://api.github.com/repos/freyja-love-and-magic/${repoName}`)
                    .then(response => response.json())
                    .then(data => {
                        descriptions[serviceName] = data.description || 'No description available';
                        
                        const tooltip = document.createElement('div');
                        tooltip.className = 'tooltip';
                        tooltip.textContent = descriptions[serviceName];
                        shape.appendChild(tooltip);
                    })
                    .catch(error => {
                        console.error(`Error fetching description for ${serviceName}:`, error);
                        descriptions[serviceName] = 'Description unavailable';
                    });
                
                fetchPromises.push(fetchPromise);
            }
        });

        // Wait for all fetches to complete then cache the results
        try {
            await Promise.all(fetchPromises);
            setCache(descriptions);
        } catch (error) {
            console.error('Error caching descriptions:', error);
        }
    };

    // Initialize tooltips
    fetchRepoDescriptions();

    // Handle gem expansion
    shapesContainer.addEventListener('click', (e) => {
        if (!isExpanded) {
            // First click: expand the gem into shapes
            shapesContainer.classList.add('expanded');
            isExpanded = true;
            // Disable parallax when expanded
            document.removeEventListener('mousemove', handleParallax);
        } else {
            shapesContainer.classList.remove('expanded');
            isExpanded = false;
        }
    });

    // Prevent navigation when clicking shapes in unexpanded state
    shapes.forEach(shape => {
        shape.addEventListener('click', (e) => {
            if (!isExpanded) {
                e.preventDefault();
            }
        });
    });

    // Add escape key to collapse
    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape' && isExpanded) {
            shapesContainer.classList.remove('expanded');
            isExpanded = false;
            // Re-enable parallax when collapsed
            document.addEventListener('mousemove', handleParallax);
        }
    });

    // Set up background
    const backgroundContainer = document.querySelector('.background-container');
    backgroundContainer.style.backgroundImage = 'url("images/Aybabtu.svg")';
    
    // Parallax effect handler
    const handleParallax = (e) => {
        const moveX = (e.clientX - window.innerWidth / 2) * 0.01;
        const moveY = (e.clientY - window.innerHeight / 2) * 0.01;
        backgroundContainer.style.transform = `translate(${moveX}px, ${moveY}px) scale(1.1)`;
        
        // Add subtle gem rotation
        if (!isExpanded) {
            const rotateX = (e.clientY - window.innerHeight / 2) * 0.02;
            const rotateY = (e.clientX - window.innerWidth / 2) * -0.02;
            shapesContainer.style.transform = `rotateX(${rotateX}deg) rotateY(${rotateY}deg)`;
        }
    };

    // Initialize parallax
    document.addEventListener('mousemove', handleParallax);
}); 
