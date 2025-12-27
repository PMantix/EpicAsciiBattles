use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Grid {
    width: i32,
    height: i32,
    cells: Vec<Cell>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Cell {
    pub tile_type: TileType,
    pub walkable: bool,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum TileType {
    Floor,
    Wall,
    Grass,
    Desert,
    Stone,
}

impl Grid {
    pub fn new(width: i32, height: i32) -> Self {
        let size = (width * height) as usize;
        let cells = vec![Cell {
            tile_type: TileType::Grass,
            walkable: true,
        }; size];
        
        Self {
            width,
            height,
            cells,
        }
    }
    
    pub fn width(&self) -> i32 {
        self.width
    }
    
    pub fn height(&self) -> i32 {
        self.height
    }
    
    pub fn get_cell(&self, x: i32, y: i32) -> Option<&Cell> {
        if x < 0 || y < 0 || x >= self.width || y >= self.height {
            return None;
        }
        let index = (y * self.width + x) as usize;
        self.cells.get(index)
    }
    
    pub fn is_walkable(&self, x: i32, y: i32) -> bool {
        self.get_cell(x, y).map(|c| c.walkable).unwrap_or(false)
    }
}
